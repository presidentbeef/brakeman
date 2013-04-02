require 'brakeman/processors/template_processor'

#Processes ERB templates using Erubis instead of erb.
class Brakeman::ErubisTemplateProcessor < Brakeman::TemplateProcessor
  
  #s(:call, TARGET, :method, ARGS)
  def process_call exp
    target = exp.target
    if sexp? target
      target = process target
    end
    method = exp.method

    #_buf is the default output variable for Erubis
    if node_type?(target, :lvar, :ivar) and (target.value == :_buf or target.value == :@output_buffer)
      if method == :<< or method == :safe_concat
        exp.arglist = process exp.arglist

        arg = exp.first_arg

        #We want the actual content
        if arg.node_type == :call and (arg.method == :to_s or arg.method == :html_safe!)
          arg = arg.target
        end

        if arg.node_type == :str #ignore plain strings
          ignore
        elsif node_type? target, :ivar and target.value == :@output_buffer
          s = Sexp.new :escaped_output, arg
          s.line(exp.line)
          @current_template[:outputs] << s
          s
        else
          s = Sexp.new :output, arg
          s.line(exp.line)
          @current_template[:outputs] << s
          s
        end
      elsif method == :to_s
        ignore
      else
        abort "Unrecognized action on buffer: #{method}"
      end
    elsif target == nil and method == :render
      exp.arglist = process exp.arglist
      make_render_in_view exp
    else
      #TODO: Is it really necessary to create a new Sexp here?
      call = make_call target, method, process_all!(exp.args)
      call.original_line = exp.original_line
      call.line(exp.line)
      call
    end
  end

  #Process blocks, ignoring :ignore exps
  def process_block exp
    exp = exp.dup
    exp.shift
    exp.map! do |e|
      res = process e
      if res.empty? or res == ignore
        nil
      else
        res
      end
    end
    block = Sexp.new(:rlist).concat(exp).compact
    block.line(exp.line)
    block
  end

  #Look for assignments to output buffer that look like this:
  #  @output_buffer.append = some_output
  #  @output_buffer.safe_append = some_output
  def process_attrasgn exp
    if exp.target.node_type == :ivar and exp.target.value == :@output_buffer
      if exp.method == :append= or exp.method == :safe_append=
        arg = exp.first_arg = process(exp.first_arg)

        if arg.node_type == :str
          ignore
        else
          s = Sexp.new :escaped_output, arg
          s.line(exp.line)
          @current_template[:outputs] << s
          s
        end
      else
        super
      end
    else
      super
    end
  end
end

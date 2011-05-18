require 'processors/template_processor'

#Processes ERB templates using Erubis instead of erb.
class ErubisTemplateProcessor < TemplateProcessor

  
  #s(:call, TARGET, :method, s(:arglist))
  def process_call exp
    target = exp[1]
    if sexp? target
      target = process target
    end
    method = exp[2]

    #_buf is the default output variable for Erubis
    if target and (target[1] == :_buf or target[1] == :output_buffer)
      if method == :<< or method == :safe_concat
        args = exp[3][1] = process(exp[3][1])

        if args.node_type == :call and args[2] == :to_s #just calling to_s on inner code 
          args = args[1]
        end

        if args.node_type == :str #ignore plain strings
          ignore
        else
          s = Sexp.new :output, args
          s.line(exp.line)
          @current_template[:outputs] << s
          s
        end
      elsif method == :to_s
        ignore
      else
        abort "Unrecognized action on _buf: #{method}"
      end
    elsif target == nil and method == :render
      exp[3] = process exp[3]
      make_render exp
    else
      args = exp[3] = process(exp[3])
      call = Sexp.new :call, target, method, args
      call.line(exp.line)
      call
    end
  end

  #Process blocks, ignoring :ignore exps
  def process_block exp
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

  #Look for assignments to output buffer
  def process_attrasgn exp
    if exp[1].node_type == :ivar and exp[1][1] == :@output_buffer
      if exp[2] == :append= or exp[2] == :safe_append=
        args = exp[3][1] = process(exp[3][1])

        if args.node_type == :str
          ignore
        else
          s = Sexp.new :escaped_output, args
          s.line(exp.line)
          @current_template[:outputs] << s
          s
        end
      else
        ignore
      end
    else
      super
    end
  end
end

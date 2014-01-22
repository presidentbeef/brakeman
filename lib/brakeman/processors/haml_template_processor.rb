require 'brakeman/processors/template_processor'

#Processes HAML templates.
class Brakeman::HamlTemplateProcessor < Brakeman::TemplateProcessor
  HAML_FORMAT_METHOD = /format_script_(true|false)_(true|false)_(true|false)_(true|false)_(true|false)_(true|false)_(true|false)/
  HAML_HELPERS = s(:colon2, s(:const, :Haml), :Helpers)
  
  #Processes call, looking for template output
  def process_call exp
    target = exp.target
    if sexp? target
      target = process target
    end

    method = exp.method

    if (call? target and target.method == :_hamlout)
      res = case method
            when :adjust_tabs, :rstrip!, :attributes #Check attributes, maybe?
              ignore
            when :options, :buffer
              exp
            when :open_tag
              process_call_args exp
            else
              arg = exp.first_arg

              if arg
                @inside_concat = true
                out = exp.first_arg = process(arg)
                @inside_concat = false
              else
                raise "Empty _hamlout.#{method}()?"
              end

              if string? out
                ignore
              else
                case method.to_s
                when "push_text"
                  build_output_from_push_text(out)
                when HAML_FORMAT_METHOD
                  if $4 == "true"
                    Sexp.new :format_escaped, out
                  else
                    Sexp.new :format, out
                  end
                else
                  raise "Unrecognized action on _hamlout: #{method}"
                end
              end

            end

      res.line(exp.line)
      res

      #_hamlout.buffer <<
      #This seems to be used rarely, but directly appends args to output buffer.
      #Has something to do with values of blocks?
    elsif sexp? target and method == :<< and is_buffer_target? target
      @inside_concat = true
      out = exp.first_arg = process(exp.first_arg)
      @inside_concat = false

      if out.node_type == :str #ignore plain strings
        ignore
      else
        s = Sexp.new(:output, out)
        @current_template[:outputs] << s
        s.line(exp.line)
        s
      end
    elsif target == nil and method == :render
      #Process call to render()
      exp.arglist = process exp.arglist
      make_render_in_view exp
    else
      #TODO: Do we really need a new Sexp here?
      call = make_call target, method, process_all!(exp.args)
      call.original_line = exp.original_line
      call.line(exp.line)
      call
    end
  end

  #If inside an output stream, only return the final expression
  def process_block exp
    exp = exp.dup
    exp.shift
    if @inside_concat
      @inside_concat = false
      exp[0..-2].each do |e|
        process e
      end
      @inside_concat = true
      process exp[-1]
    else
      exp.map! do |e|
        res = process e
        if res.empty?
          nil
        else
          res
        end
      end
      Sexp.new(:rlist).concat(exp).compact
    end
  end

  #Checks if the buffer is the target in a method call Sexp.
  #TODO: Test this
  def is_buffer_target? exp
    exp.node_type == :call and
    node_type? exp.target, :lvar and
    exp.target.value == :_hamlout and
    exp.method == :buffer
  end

  #HAML likes to put interpolated values into _hamlout.push_text
  #but we want to handle those individually
  def build_output_from_push_text exp
    if node_type? exp, :string_interp, :dstr
      exp.map! do |e|
        if sexp? e
          if node_type? e, :string_eval, :evstr
            e = e.value
          end

          get_pushed_value e
        else
          e
        end
      end
    end
  end

  #Gets outputs from values interpolated into _hamlout.push_text
  def get_pushed_value exp
    return exp unless sexp? exp
    
    case exp.node_type
    when :format
      exp.node_type = :output
      @current_template[:outputs] << exp
      exp
    when :format_escaped
      exp.node_type = :escaped_output
      @current_template[:outputs] << exp
      exp
    when :str, :ignore, :output, :escaped_output
      exp
    when :block, :rlist, :string_interp, :dstr
      exp.map! { |e| get_pushed_value e }
    else
      if call? exp and exp.target == HAML_HELPERS and exp.method == :html_escape
        s = Sexp.new(:escaped_output, exp.first_arg)
      else
        s = Sexp.new(:output, exp)
      end

      s.line(exp.line)
      @current_template[:outputs] << s
      s
    end
  end
end

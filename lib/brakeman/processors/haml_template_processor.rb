require 'brakeman/processors/template_processor'

#Processes HAML templates.
class Brakeman::HamlTemplateProcessor < Brakeman::TemplateProcessor
  HAML_FORMAT_METHOD = /format_script_(true|false)_(true|false)_(true|false)_(true|false)_(true|false)_(true|false)_(true|false)/
  
  def initialize *args
    super

    @tracker.libs.each do |name, lib|
      if name.to_s =~ /^Haml::Filters/
        begin
          require lib[:file]
        rescue Exception => e
          if OPTIONS[:debug]
            raise e
          end
        end
      end
    end
  end

  #Processes call, looking for template output
  def process_call exp
    target = exp[1]
    if sexp? target
      target = process target
    end

    method = exp[2]

    if (sexp? target and target[2] == :_hamlout) or target == :_hamlout
      res = case method
            when :adjust_tabs, :rstrip!
              ignore
            when :options
              Sexp.new :call, :_hamlout, :options, exp[3]
            when :buffer
              Sexp.new :call, :_hamlout, :buffer, exp[3]
            when :open_tag
              Sexp.new(:tag, process(exp[3]))
            else
              arg = exp[3][1]

              if arg
                @inside_concat = true
                out = exp[3][1] = process(arg)
                @inside_concat = false
              else
                raise Exception.new("Empty _hamlout.#{method}()?")
              end

              if string? out
                ignore
              else
                case method.to_s
                when "push_text"
                  s = Sexp.new(:output, out)
                  @current_template[:outputs] << s
                  s
                when HAML_FORMAT_METHOD
                  if $4 == "true"
                    Sexp.new :format_escaped, out
                  else
                    Sexp.new :format, out
                  end
                else
                  raise Exception.new("Unrecognized action on _hamlout: #{method}")
                end
              end

            end

      res.line(exp.line)
      res

      #_hamlout.buffer <<
      #This seems to be used rarely, but directly appends args to output buffer
    elsif sexp? target and method == :<< and is_buffer_target? target
      @inside_concat = true
      out = exp[3][1] = process(exp[3][1])
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
      exp[3] = process exp[3]
      make_render exp
    else
      args = process exp[3]
      call = Sexp.new :call, target, method, args
      call.line(exp.line)
      call
    end
  end

  #If inside an output stream, only return the final expression
  def process_block exp
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
  def is_buffer_target? exp
    exp.node_type == :call and exp[1] == :_hamlout and exp[2] == :buffer
  end
end

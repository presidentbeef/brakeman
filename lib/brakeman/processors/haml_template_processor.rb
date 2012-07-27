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
          if @tracker.options[:debug]
            raise e
          end
        end
      end
    end
  end

  #Processes call, looking for template output
  def process_call exp
    target = exp.target
    if sexp? target
      target = process target
    end

    method = exp.method

    if (call? target and target.method == :_hamlout) or target == :_hamlout
      res = case method
            when :adjust_tabs, :rstrip!, :attributes #Check attributes, maybe?
              ignore
            when :options
              Sexp.new :call, :_hamlout, :options, exp.arglist
            when :buffer
              Sexp.new :call, :_hamlout, :buffer, exp.arglist
            when :open_tag
              Sexp.new(:tag, process(exp.arglist))
            else
              arg = exp.args.first

              if arg
                @inside_concat = true
                out = exp.arglist[1] = process(arg)
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
      out = exp.arglist[1] = process(exp.arglist[1])
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
      args = process exp.arglist
      call = Sexp.new :call, target, method, args
      call.original_line(exp.original_line)
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

require 'brakeman/processors/template_processor'

#Processes HAML templates.
class Brakeman::HamlTemplateProcessor < Brakeman::TemplateProcessor
  HAML_FORMAT_METHOD = /format_script_(true|false)_(true|false)_(true|false)_(true|false)_(true|false)_(true|false)_(true|false)/
  HAML_HELPERS = s(:colon2, s(:const, :Haml), :Helpers)
  JAVASCRIPT_FILTER = s(:colon2, s(:colon2, s(:const, :Haml), :Filters), :Javascript)
  COFFEE_FILTER = s(:colon2, s(:colon2, s(:const, :Haml), :Filters), :Coffee)

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
                exp.first_arg = process(arg)
                out = normalize_output(exp.first_arg)
                @inside_concat = false
              else
                raise "Empty _hamlout.#{method}()?"
              end

              if string? out
                ignore
              else
                r = case method.to_s
                    when "push_text"
                      build_output_from_push_text(out)
                    when HAML_FORMAT_METHOD
                      if $4 == "true"
                        if string_interp? out
                          build_output_from_push_text(out, :escaped_output)
                        else
                          Sexp.new :format_escaped, out
                        end
                      else
                        if string_interp? out
                          build_output_from_push_text(out)
                        else
                          Sexp.new :format, out
                        end
                      end

                    else
                      raise "Unrecognized action on _hamlout: #{method}"
                    end

                @javascript = false
                r
              end
            end

      res.line(exp.line)
      res

      #_hamlout.buffer <<
      #This seems to be used rarely, but directly appends args to output buffer.
      #Has something to do with values of blocks?
    elsif sexp? target and method == :<< and is_buffer_target? target
      @inside_concat = true
      exp.first_arg = process(exp.first_arg)
      out = normalize_output(exp.first_arg)
      @inside_concat = false

      if out.node_type == :str #ignore plain strings
        ignore
      else
        add_output out
      end
    elsif target == nil and method == :render
      #Process call to render()
      exp.arglist = process exp.arglist
      make_render_in_view exp
    elsif target == nil and method == :find_and_preserve and exp.first_arg
      process exp.first_arg
    elsif method == :render_with_options
      if target == JAVASCRIPT_FILTER or target == COFFEE_FILTER
        @javascript = true
      end

      process exp.first_arg
    else
      exp.target = target
      exp.arglist = process exp.arglist
      exp
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
  def build_output_from_push_text exp, default = :output
    if string_interp? exp
      exp.map! do |e|
        if sexp? e
          if node_type? e, :evstr and e[1]
            e = e.value
          end

          get_pushed_value e, default
        else
          e
        end
      end
    end
  end

  #Gets outputs from values interpolated into _hamlout.push_text
  def get_pushed_value exp, default = :output
    return exp unless sexp? exp

    case exp.node_type
    when :format
      exp.node_type = :output
      @current_template.add_output exp
      exp
    when :format_escaped
      exp.node_type = :escaped_output
      @current_template.add_output exp
      exp
    when :str, :ignore, :output, :escaped_output
      exp
    when :block, :rlist, :dstr
      exp.map! { |e| get_pushed_value e }
    when :if
      clauses = [get_pushed_value(exp.then_clause), get_pushed_value(exp.else_clause)].compact

      if clauses.length > 1
        s(:or, *clauses)
      else
        clauses.first
      end
    else
      if call? exp and exp.target == HAML_HELPERS and exp.method == :html_escape
        add_escaped_output exp.first_arg
      elsif @javascript and call? exp and (exp.method == :j or exp.method == :escape_javascript)
        add_escaped_output exp.first_arg
      else
        add_output exp, default
      end
    end
  end
end

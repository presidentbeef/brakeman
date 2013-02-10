require 'brakeman/processors/template_processor'

class Brakeman::SlimTemplateProcessor < Brakeman::TemplateProcessor
  include Brakeman::RenderHelper

  SAFE_BUFFER = s(:call, s(:colon2, s(:const, :ActiveSupport), :SafeBuffer), :new)
  TEMPLE_UTILS = s(:colon2, s(:colon3, :Temple), :Utils)

  def process_call exp
    target = exp.target
    method = exp.method

    if target == SAFE_BUFFER and method == :safe_concat
      @inside_concat = true
      arg = process exp.first_arg
      @inside_concat = false

      if call? arg and arg.method == :to_s
        arg = arg.target
      end

      if is_escaped? arg
        make_escaped_output arg
      elsif string? arg
        ignore
      elsif node_type? arg, :interp, :dstr
        process_inside_interp arg
        ignore
      else
        make_output arg
      end
    elsif target == nil and method == :render
      exp.arglist = process exp.arglist
      make_render_in_view exp
    else
      call = make_call target, method, process_all!(exp.args)
      call.original_line(exp.original_line)
      call.line(exp.line)
      call
    end
  end

  def make_output exp
    s = Sexp.new :output, exp
    s.line(exp.line)
    @current_template[:outputs] << s
    s
  end

  def make_escaped_output exp
    s = Sexp.new :escaped_output, exp.first_arg
    s.line(exp.line)
    @current_template[:outputs] << s
    s
  end

  #Slim likes to interpolate output into strings then pass them to safe_concat.
  #Better to pull those values out directly.
  def process_inside_interp exp
    exp.each do |e|
      if node_type? e, :evstr, :string_eval
        if is_escaped? e.value
          make_escaped_output e.value
        else
          make_output e.value
        end
      end
    end
  end

  def is_escaped? exp
    call? exp and
    exp.target == TEMPLE_UTILS and
    exp.method == :escape_html
  end
end

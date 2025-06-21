require 'brakeman/processors/slim_template_processor'

class Brakeman::Haml6TemplateProcessor < Brakeman::SlimTemplateProcessor
  HAML_UTILS = s(:colon2, s(:colon3, :Haml), :Util)
  # @output_buffer = output_buffer || ActionView::OutputBuffer.new
  AV_SAFE_BUFFER = s(:or, s(:call, nil, :output_buffer), s(:call, s(:colon2, s(:const, :ActionView), :OutputBuffer), :new))

  def is_escaped? exp
    call? exp and
    exp.target == HAML_UTILS and
    (exp.method == :escape_html or exp.method == :escape_html_safe)
  end

  def output_buffer? exp
    exp == OUTPUT_BUFFER or
      exp == AV_SAFE_BUFFER
  end
end

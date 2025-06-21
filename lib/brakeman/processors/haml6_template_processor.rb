require 'brakeman/processors/slim_template_processor'

class Brakeman::Haml6TemplateProcessor < Brakeman::SlimTemplateProcessor
  HAML_UTILS = s(:colon2, s(:colon3, :Haml), :Util)
  HAML_UTILS2 = s(:colon2, s(:const, :Haml), :Util)
  # @output_buffer = output_buffer || ActionView::OutputBuffer.new
  AV_SAFE_BUFFER = s(:or, s(:call, nil, :output_buffer), s(:call, s(:colon2, s(:const, :ActionView), :OutputBuffer), :new))

  def is_escaped? exp
    return unless call? exp

    html_escaped? exp or
      javascript_escaped? exp
  end

  def javascript_escaped? call
    # TODO: Adding here to match existing behavior for HAML,
    # but really this is not safe and needs to be revisited
      call.method == :j or
      call.method == :escape_javascript
  end

  def html_escaped? call
    (call.target == HAML_UTILS or call.target == HAML_UTILS2) and
      (call.method == :escape_html or call.method == :escape_html_safe)
  end

  def output_buffer? exp
    exp == OUTPUT_BUFFER or
      exp == AV_SAFE_BUFFER
  end
end

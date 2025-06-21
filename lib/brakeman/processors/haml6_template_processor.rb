require 'brakeman/processors/slim_template_processor'

class Brakeman::Haml6TemplateProcessor < Brakeman::SlimTemplateProcessor
  HAML_UTILS = s(:colon2, s(:colon3, :Haml), :Util)

  def is_escaped? exp
    call? exp and
    exp.target == HAML_UTILS and
    (exp.method == :escape_html or exp.method == :escape_html_safe)
  end
end

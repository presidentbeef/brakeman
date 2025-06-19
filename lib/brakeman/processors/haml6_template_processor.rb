require 'brakeman/processors/slim_template_processor'

class Brakeman::Haml6TemplateProcessor < Brakeman::SlimTemplateProcessor
  TEMPLE_UTILS = s(:colon2, s(:colon3, :Haml), :Util)
end

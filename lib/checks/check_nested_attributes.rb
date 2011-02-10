require 'checks/base_check'
require 'processors/lib/find_call'

#Check for vulnerability in nested attributes in Rails 2.3.9 and 3.0.0
#http://groups.google.com/group/rubyonrails-security/browse_thread/thread/f9f913d328dafe0c
class CheckNestedAttributes < BaseCheck
  Checks.add self

  def run_check
    version = tracker.config[:rails_version]

    if (version == "2.3.9" or version == "3.0.0") and uses_nested_attributes?
      message = "Vulnerability in nested attributes (CVE-2010-3933). Upgrade to Rails version "

      if version == "2.3.9"
        message << "2.3.10"
      else
        message << "3.0.1"
      end

      warn :warning_type => "Nested Attributes",
        :message => message,
        :confidence => CONFIDENCE[:high]
    end
  end

  def uses_nested_attributes?
    tracker.models.each do |name, model|
      return true if model[:options][:accepts_nested_attributes_for]
    end

    false
  end
end

require 'brakeman/checks/base_check'

#Check for vulnerability in nested attributes in Rails 2.3.9 and 3.0.0
#http://groups.google.com/group/rubyonrails-security/browse_thread/thread/f9f913d328dafe0c
class Brakeman::CheckNestedAttributes < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for nested attributes vulnerability in Rails 2.3.9 and 3.0.0"

  def run_check
    version = rails_version

    if (version == "2.3.9" or version == "3.0.0") and uses_nested_attributes?
      message = "Vulnerability in nested attributes (CVE-2010-3933). Upgrade to Rails version "

      if version == "2.3.9"
        message << "2.3.10"
      else
        message << "3.0.1"
      end

      warn :warning_type => "Nested Attributes",
        :warning_code => :CVE_2010_3933,
        :message => message,
        :confidence => :high,
        :gem_info => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/-fkT0yja_gw/discussion"
    end
  end

  def uses_nested_attributes?
    active_record_models.each do |_name, model|
      return true if model.options[:accepts_nested_attributes_for]
    end

    false
  end
end

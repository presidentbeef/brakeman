require 'brakeman/checks/base_check'

class Brakeman::CheckHeaderDoS < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for header DoS (CVE-2013-6414)"

  def run_check
    if (version_between? "3.0.0", "3.2.15" or version_between? "4.0.0", "4.0.1") and not has_workaround?
      message = "Rails #{rails_version} has a denial of service vulnerability (CVE-2013-6414). Upgrade to Rails version "

      if version_between? "3.0.0", "3.2.15"
        message << "3.2.16"
      else
        message << "4.0.2"
      end

      warn :warning_type => "Denial of Service",
        :warning_code => :CVE_2013_6414,
        :message => message,
        :confidence => :medium,
        :gem_info => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/msg/ruby-security-ann/A-ebV4WxzKg/KNPTbX8XAQUJ"
    end
  end

  def has_workaround?
    tracker.check_initializers(:ActiveSupport, :on_load).any? and
    tracker.check_initializers(:"ActionView::LookupContext::DetailsKey", :class_eval).any?
  end
end

require 'brakeman/checks/base_check'

class Brakeman::CheckI18nXSS < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for i18n XSS (CVE-2013-4491)"

  def run_check
    if (version_between? "3.0.6", "3.2.15" or version_between? "4.0.0", "4.0.1") and not has_workaround?

      i18n_gem = tracker.config[:gems][:i18n][:version] if tracker.config[:gems][:i18n]
      file = tracker.config[:gems][:rails][:file] if tracker.config[:gems][:rails]
      if file
        message = "Rails #{tracker.config[:rails_version]} (#{file}) has an XSS vulnerability in i18n (CVE-2013-4491). Upgrade to Rails version "
      else
        message = "Rails #{tracker.config[:rails_version]} has an XSS vulnerability in i18n (CVE-2013-4491). Upgrade to Rails version "
      end

      if version_between? "3.0.6", "3.1.99" and version_before i18n_gem, "0.5.1"
        message << "3.2.16 or i18n 0.5.1"
      elsif version_between? "3.2.0", "4.0.1" and version_before i18n_gem, "0.6.6"
        message << "4.0.2 or i18n 0.6.6"
      else
        return
      end

      warn :warning_type => "Cross Site Scripting",
        :warning_code => :CVE_2013_4491,
        :message => message,
        :confidence => CONFIDENCE[:med],
        :file => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/msg/ruby-security-ann/pLrh6DUw998/bLFEyIO4k_EJ"
    end
  end

  def version_before gem_version, target
    return true unless gem_version
    gem_version.split('.').map(&:to_i).zip(target.split('.').map(&:to_i)).each do |gv, t|
      if gv < t
        return true
      elsif gv > t
        return false
      end
    end

    false
  end

  def has_workaround?
    tracker.check_initializers(:I18n, :const_defined?).any? do |match|
      match.last.first_arg == s(:lit, :MissingTranslation)
    end
  end
end

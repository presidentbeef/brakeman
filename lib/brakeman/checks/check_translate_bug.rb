require 'brakeman/checks/base_check'

#Check for vulnerability in translate() helper that allows cross-site scripting
class Brakeman::CheckTranslateBug < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Report XSS vulnerability in translate helper"

  def run_check
    return if lts_version? '2.3.18.6'
    if (version_between?('2.3.0', '2.3.99') and tracker.config.escape_html?) or
        version_between?('3.0.0', '3.0.10') or
        version_between?('3.1.0', '3.1.1')

      confidence = if uses_translate?
        :high
      else
        :medium
      end

      description = "have a vulnerability in the translate helper with keys ending in _html"

      message = if rails_version =~ /^3\.1/
        "Versions before 3.1.2 #{description}."
      elsif rails_version =~ /^3\.0/
        "Versions before 3.0.11 #{description}."
      else
        "Rails 2.3.x using the rails_xss plugin #{description}."
      end

      warn :warning_type => "Cross-Site Scripting",
        :warning_code => :translate_vuln,
        :message => message,
        :confidence => confidence,
        :gem_info => gemfile_or_environment,
        :link_path => "http://groups.google.com/group/rubyonrails-security/browse_thread/thread/2b61d70fb73c7cc5"
    end
  end

  def uses_translate?
    Brakeman.debug "Finding calls to translate() or t()"

    tracker.find_call(:target => nil, :methods => [:t, :translate]).any?
  end
end

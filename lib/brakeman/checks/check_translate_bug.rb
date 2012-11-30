require 'brakeman/checks/base_check'

#Check for vulnerability in translate() helper that allows cross-site scripting
class Brakeman::CheckTranslateBug < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Report XSS vulnerability in translate helper"

  def run_check
    if (version_between?('2.3.0', '2.3.99') and tracker.config[:escape_html]) or
        version_between?('3.0.0', '3.0.10') or
        version_between?('3.1.0', '3.1.1')

      confidence = if uses_translate?
        CONFIDENCE[:high]
      else
        CONFIDENCE[:med]
      end

      version = tracker.config[:rails_version]
      description = "have a vulnerability in the translate helper with keys ending in _html"

      message = if version =~ /^3\.1/
        "Versions before 3.1.2 #{description}."
      elsif version =~ /^3\.0/
        "Versions before 3.0.11 #{description}."
      else
        "Rails 2.3.x using the rails_xss plugin #{description}}."
      end

      warn :warning_type => "Cross Site Scripting",
        :message => message,
        :confidence => confidence,
        :file => gemfile_or_environment,
        :link_path => "http://groups.google.com/group/rubyonrails-security/browse_thread/thread/2b61d70fb73c7cc5"
    end
  end

  def uses_translate?
    Brakeman.debug "Finding calls to translate() or t()"

    tracker.find_call(:target => nil, :methods => [:t, :translate]).any?
  end
end

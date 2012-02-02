require 'brakeman/checks/base_check'

#Check for vulnerability in translate() helper that allows cross-site scripting
#http://groups.google.com/group/rubyonrails-security/browse_thread/thread/2b61d70fb73c7cc5
class Brakeman::CheckTranslateBug < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Report XSS vulnerability in translate helper"

  def run_check
    if (version_between?('2.3.0', '2.3.99') and tracker.config[:escape_html]) or
        version_between?('3.0.0', '3.0.10') or
        version_between?('3.1.0', '3.1.1')

      if uses_translate?
        confidence = CONFIDENCE[:high]
      else
        confidence = CONFIDENCE[:med]
      end

      version = tracker.config[:rails_version]

      if version =~ /^3\.1/
        message = "Versions before 3.1.2 have a vulnerability in the translate helper."
      elsif version =~ /^3\.0/
        message = "Versions before 3.0.11 have a vulnerability in translate helper."
      else
        message = "Rails 2.3.x using the rails_xss plugin have a vulnerability in translate helper."
      end

      warn :warning_type => "Cross Site Scripting",
        :message => message,
        :confidence => confidence,
        :file => gemfile_or_environment
    end
  end

  def uses_translate?
    Brakeman.debug "Finding calls to translate() or t()"

    not tracker.find_call(:target => nil, :methods => [:t, :translate]).empty?
  end
end

require 'checks/base_check'
require 'processors/lib/find_call'

#Checks for uses of strip_tags in Rails versions before 2.3.13 and 3.0.10
#http://groups.google.com/group/rubyonrails-security/browse_thread/thread/2b9130749b74ea12
class CheckStripTags < BaseCheck
  Checks.add self

  def run_check
    if (version_between?('2.0.0', '2.3.12') or 
        version_between?('3.0.0', '3.0.9')) and uses_strip_tags?

      if tracker.config[:rails_version] =~ /^3/
        message = "Versions before 3.0.10 have a vulnerability in strip_tags: CVE-2011-2931"
      else
        message = "Versions before 2.3.13 have a vulnerability in strip_tags: CVE-2011-2931"
      end

      warn :warning_type => "Cross Site Scripting",
        :message => message,
        :confidence => CONFIDENCE[:high]
    end
  end

  def uses_strip_tags?
    not tracker.find_call([], :strip_tags).empty?
  end
end

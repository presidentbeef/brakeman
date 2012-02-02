require 'brakeman/checks/base_check'

#Check for filter skipping vulnerability
#http://groups.google.com/group/rubyonrails-security/browse_thread/thread/3420ac71aed312d6
class Brakeman::CheckFilterSkipping < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for versions 3.0-3.0.9 which had a vulnerability in filters"

  def run_check
    if version_between?('3.0.0', '3.0.9') and uses_arbitrary_actions?

      warn :warning_type => "Default Routes",
        :message => "Versions before 3.0.10 have a vulnerability which allows filters to be bypassed: CVE-2011-2929",
        :confidence => CONFIDENCE[:high],
        :file => gemfile_or_environment
    end
  end

  def uses_arbitrary_actions?
    tracker.routes.each do |name, actions|
      if actions == :allow_all_actions
        return true
      end
    end

    false
  end
end

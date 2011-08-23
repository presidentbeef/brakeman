require 'checks/base_check'
require 'processors/lib/find_call'

#Check for filter skipping vulnerability
#http://groups.google.com/group/rubyonrails-security/browse_thread/thread/3420ac71aed312d6
class CheckFilterSkipping < BaseCheck
  Checks.add self

  def run_check
    if version_between?('3.0.0', '3.0.9') and uses_arbitrary_actions?

      warn :warning_type => "Default Routes",
        :message => "Versions before 3.0.10 have a vulnerability which allows filters to be bypassed: CVE-2011-2929",
        :confidence => CONFIDENCE[:high]
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

require 'checks/base_check'
require 'processors/lib/find_call'

#Warn about response splitting in Rails versions before 2.3.13
#http://groups.google.com/group/rubyonrails-security/browse_thread/thread/6ffc93bde0298768
class CheckResponseSplitting < BaseCheck
  Checks.add self

  def run_check
    if version_between?('2.3.0', '2.3.13')

      warn :warning_type => "Response Splitting",
        :message => "Versions before 2.3.14 have a vulnerability content type handling allowing injection of headers: CVE-2011-3186",
        :confidence => CONFIDENCE[:med]

    end
  end
end

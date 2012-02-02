require 'brakeman/checks/base_check'

#Warn about response splitting in Rails versions before 2.3.13
#http://groups.google.com/group/rubyonrails-security/browse_thread/thread/6ffc93bde0298768
class Brakeman::CheckResponseSplitting < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Report response splitting in Rails 2.3.0 - 2.3.13"

  def run_check
    if version_between?('2.3.0', '2.3.13')

      warn :warning_type => "Response Splitting",
        :message => "Versions before 2.3.14 have a vulnerability content type handling allowing injection of headers: CVE-2011-3186",
        :confidence => CONFIDENCE[:med],
        :file => gemfile_or_environment
    end
  end
end

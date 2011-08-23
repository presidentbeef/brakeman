require 'checks/base_check'
require 'processors/lib/find_call'

#Check for versions with vulnerable html escape method
#http://groups.google.com/group/rubyonrails-security/browse_thread/thread/56bffb5923ab1195
class CheckEscapeFunction < BaseCheck
  Checks.add self

  def run_check
    if version_between?('2.0.0', '2.3.13') and RUBY_VERSION < '1.9.0' 

      warn :warning_type => 'Cross Site Scripting',
        :message => 'Versions before 2.3.14 have a vulnerability in escape method when used with Ruby 1.8: CVE-2011-2931',
        :confidence => CONFIDENCE[:high]
    end
  end
end

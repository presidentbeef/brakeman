require 'brakeman/checks/base_check'

#Check for versions with vulnerable html escape method
#http://groups.google.com/group/rubyonrails-security/browse_thread/thread/56bffb5923ab1195
class Brakeman::CheckEscapeFunction < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for versions before 2.3.14 which have a vulnerable escape method"

  def run_check
    if version_between?('2.0.0', '2.3.13') and RUBY_VERSION < '1.9.0' 

      warn :warning_type => 'Cross Site Scripting',
        :warning_code => :CVE_2011_2931,
        :message => 'Versions before 2.3.14 have a vulnerability in escape method when used with Ruby 1.8: CVE-2011-2931',
        :confidence => CONFIDENCE[:high],
        :file => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/Vr_7WSOrEZU/discussion"
    end
  end
end

require 'brakeman/checks/base_check'

class Brakeman::CheckSymbolDoS < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for versions with ActiveRecord symbol denial of service" 

  def run_check
    fix_version = case
      when version_between?('2.0.0', '2.3.17')
        '2.3.18'
      when version_between?('3.1.0', '3.1.11')
        '3.1.12'
      when version_between?('3.2.0', '3.2.12')
        '3.2.13'
      else
        return
      end

    unless active_record_models.empty?
      warn :warning_type => "Denial of Service",
        :warning_code => :CVE_2013_1854,
        :message => "Rails #{tracker.config[:rails_version]} has a denial of service vulnerability in ActiveRecord: upgrade to #{fix_version} or patch",
        :confidence => CONFIDENCE[:med],
        :file => gemfile_or_environment,
        :link => "https://groups.google.com/d/msg/rubyonrails-security/jgJ4cjjS8FE/BGbHRxnDRTIJ"
    end
  end
end

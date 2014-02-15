require 'brakeman/checks/base_check'

#sanitize and sanitize_css are vulnerable:
#CVE-2013-1855 and CVE-2013-1857
class Brakeman::CheckSanitizeMethods < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for versions with vulnerable sanitize and sanitize_css"

  def run_check
    @fix_version = case
      when version_between?('2.0.0', '2.3.17')
        '2.3.18'
      when version_between?('3.0.0', '3.0.99')
        '3.2.13'
      when version_between?('3.1.0', '3.1.11')
        '3.1.12'
      when version_between?('3.2.0', '3.2.12')
        '3.2.13'
      else
        return
      end

    check_cve_2013_1855
    check_cve_2013_1857
  end

  def check_cve_2013_1855
    check_for_cve :sanitize_css, :CVE_2013_1855, "https://groups.google.com/d/msg/rubyonrails-security/4_QHo4BqnN8/_RrdfKk12I4J"
  end

  def check_cve_2013_1857
    check_for_cve :sanitize, :CVE_2013_1857, "https://groups.google.com/d/msg/rubyonrails-security/zAAU7vGTPvI/1vZDWXqBuXgJ"
  end

  def check_for_cve method, code, link
    tracker.find_call(:target => false, :method => method).each do |result|
      next if duplicate? result
      add_result result

      message = "Rails #{tracker.config[:rails_version]} has a vulnerability in #{method}: upgrade to #{@fix_version} or patch"

      if include_user_input? result[:call]
        confidence = CONFIDENCE[:high]
      else
        confidence = CONFIDENCE[:medium]
      end

      warn :result => result,
        :warning_type => "Cross Site Scripting",
        :warning_code => code,
        :message => message,
        :confidence => CONFIDENCE[:high],
        :link_path => link
    end
  end
end

require 'brakeman/checks/base_check'

class Brakeman::CheckXMLDoS < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for XML denial of service (CVE-2015-3227)"

  def run_check
    fix_version = case
                  when version_between?("4.1.0", "4.1.10")
                    "4.1.11"
                  when version_between?("4.2.0", "4.2.1")
                    "4.2.2"
                  when version_between?("4.1.11", "4.1.99")
                    return
                  when version_between?("4.2.2", "9.9.9")
                    return
                  when has_workaround?
                    return
                  else
                    "4.2.2"
                  end

    message = "Rails #{tracker.config[:rails_version]} is vulnerable to denial of service via XML parsing (CVE-2015-3227). Upgrade to Rails version #{fix_version}"

    warn :warning_type => "Denial of Service",
      :warning_code => :CVE_2015_3227,
      :message => message,
      :confidence => CONFIDENCE[:med],
      :gem_info => gemfile_or_environment,
      :link_path => "repos/canvas-lms/config/application.rb"
  end

  def has_workaround?
    tracker.check_initializers(:"ActiveSupport::XmlMini", :backend=).any? do |match|
      arg = match.call.first_arg
      if string? arg
        value = arg.value
        value == 'Nokogiri' or value == 'LibXML'
      end
    end
  end
end

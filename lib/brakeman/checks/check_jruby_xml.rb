require 'brakeman/checks/base_check'

class Brakeman::CheckJRubyXML < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for versions with JRuby XML parsing backend"

  def run_check
    return unless RUBY_PLATFORM == "java"

    fix_version = case
      when version_between?('3.0.0', '3.0.99')
        '3.2.13'
      when version_between?('3.1.0', '3.1.11')
        '3.1.12'
      when version_between?('3.2.0', '3.2.12')
        '3.2.13'
      else
        return
      end

    #Check for workaround
    tracker.check_initializers(:"ActiveSupport::XmlMini", :backend=).each do |result|
      arg = result.call.first_arg

      if string? arg and arg.value == "REXML"
        return
      end
    end

    warn :warning_type => "File Access",
      :warning_code => :CVE_2013_1856,
      :message => "Rails #{tracker.config[:rails_version]} with JRuby has a vulnerability in XML parser: upgrade to #{fix_version} or patch",
      :confidence => CONFIDENCE[:high],
      :file => gemfile_or_environment,
      :link => "https://groups.google.com/d/msg/rubyonrails-security/KZwsQbYsOiI/5kUV7dSCJGwJ"
  end
end

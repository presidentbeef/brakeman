require 'brakeman/checks/base_check'

class Brakeman::CheckBasicAuthTimingAttack < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Check for timing attack in basic auth (CVE-2015-7576)"

  def run_check
    @upgrade = case
               when version_between?("0.0.0", "3.2.22")
                 "3.2.22.1"
               when version_between?("4.0.0", "4.1.14")
                 "4.1.14.1"
               when version_between?("4.2.0", "4.2.5")
                 "4.2.5.1"
               else
                 return
               end

    check_basic_auth_filter
    check_basic_auth_call
  end

  def check_basic_auth_filter
    controllers = tracker.controllers.select do |name, c|
      c.options[:http_basic_authenticate_with]
    end

    Hash[controllers].each do |name, controller|
      controller.options[:http_basic_authenticate_with].each do |call|
        warn :controller => name,
          :warning_type => "Timing Attack",
          :warning_code => :CVE_2015_7576,
          :message => "Basic authentication in Rails #{rails_version} is vulnerable to timing attacks. Upgrade to #@upgrade",
          :code => call,
          :confidence => CONFIDENCE[:high],
          :file => controller.file,
          :link => "https://groups.google.com/d/msg/rubyonrails-security/ANv0HDHEC3k/mt7wNGxbFQAJ"
      end
    end
  end

  def check_basic_auth_call
    # This is relatively unusual, but found in the wild
    tracker.find_call(:target => nil, :method => :http_basic_authenticate_with).each do |result|
      warn :result => result,
        :warning_type => "Timing Attack",
        :warning_code => :CVE_2015_7576,
        :message => "Basic authentication in Rails #{rails_version} is vulnerable to timing attacks. Upgrade to #@upgrade",
        :confidence => CONFIDENCE[:high],
        :link => "https://groups.google.com/d/msg/rubyonrails-security/ANv0HDHEC3k/mt7wNGxbFQAJ"
    end
  end
end

require 'brakeman/checks/base_check'

#Checks that +protect_from_forgery+ is set in the ApplicationController.
#
#Also warns for CSRF weakness in certain versions of Rails:
#http://groups.google.com/group/rubyonrails-security/browse_thread/thread/2d95a3cc23e03665
class Brakeman::CheckForgerySetting < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Verifies that protect_from_forgery is enabled in ApplicationController"

  def run_check
    app_controller = tracker.controllers[:ApplicationController]
    if tracker.config[:rails][:action_controller] and
      tracker.config[:rails][:action_controller][:allow_forgery_protection] == Sexp.new(:false)

      warn :controller => :ApplicationController,
        :warning_type => "Cross-Site Request Forgery",
        :warning_code => :csrf_protection_disabled,
        :message => "Forgery protection is disabled",
        :confidence => CONFIDENCE[:high],
        :file => app_controller[:files].first

    elsif app_controller and not app_controller[:options][:protect_from_forgery]

      warn :controller => :ApplicationController,
        :warning_type => "Cross-Site Request Forgery",
        :warning_code => :csrf_protection_missing,
        :message => "'protect_from_forgery' should be called in ApplicationController",
        :confidence => CONFIDENCE[:high],
        :file => app_controller[:files].first

    elsif version_between? "2.1.0", "2.3.10"

      warn :controller => :ApplicationController,
        :warning_type => "Cross-Site Request Forgery",
        :warning_code => :CVE_2011_0447,
        :message => "CSRF protection is flawed in unpatched versions of Rails #{tracker.config[:rails_version]} (CVE-2011-0447). Upgrade to 2.3.11 or apply patches as needed",
        :confidence => CONFIDENCE[:high],
        :file => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/LZWjzCPgNmU/discussion"

    elsif version_between? "3.0.0", "3.0.3"

      warn :controller => :ApplicationController,
        :warning_type => "Cross-Site Request Forgery",
        :warning_code => :CVE_2011_0447,
        :message => "CSRF protection is flawed in unpatched versions of Rails #{tracker.config[:rails_version]} (CVE-2011-0447). Upgrade to 3.0.4 or apply patches as needed",
        :confidence => CONFIDENCE[:high],
        :file => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/LZWjzCPgNmU/discussion"
    end
  end
end

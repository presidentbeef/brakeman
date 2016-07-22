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
    return unless app_controller and app_controller.ancestor? :"ActionController::Base"

    if tracker.config.allow_forgery_protection?
      csrf_warning :warning_code => :csrf_protection_disabled,
        :message => "Forgery protection is disabled"

    elsif app_controller and not app_controller.protect_from_forgery?
      csrf_warning :warning_code => :csrf_protection_missing,
        :message => "'protect_from_forgery' should be called in ApplicationController",
        :line => app_controller.top_line

    elsif version_between? "2.1.0", "2.3.10"
      cve_2011_0447 "2.3.11"

    elsif version_between? "3.0.0", "3.0.3"
      cve_2011_0447 "3.0.4"

    elsif version_between? "4.0.0", "100.0.0" and forgery_opts = app_controller.options[:protect_from_forgery]
      unless forgery_opts.is_a?(Array) and sexp?(forgery_opts.first) and
          access_arg = hash_access(forgery_opts.first.first_arg, :with) and symbol? access_arg and
          access_arg.value == :exception

        args = {
          :warning_code => :csrf_not_protected_by_raising_exception,
          :message => "protect_from_forgery should be configured with 'with: :exception'",
          :confidence => CONFIDENCE[:med]
        }

        args.merge!(:code => forgery_opts.first) if forgery_opts.is_a?(Array)

        csrf_warning args
      end
    end
  end

  def csrf_warning opts
    opts = {
      :controller => :ApplicationController,
      :warning_type => "Cross-Site Request Forgery",
      :confidence => CONFIDENCE[:high],
      :file => tracker.controllers[:ApplicationController].file
    }.merge opts

    warn opts
  end

  def cve_2011_0447 new_version
    csrf_warning :warning_code => :CVE_2011_0447,
      :message => "CSRF protection is flawed in unpatched versions of Rails #{rails_version} (CVE-2011-0447). Upgrade to #{new_version} or apply patches as needed",
      :gem_info => gemfile_or_environment,
      :file => nil,
      :link_path => "https://groups.google.com/d/topic/rubyonrails-security/LZWjzCPgNmU/discussion"
  end
end

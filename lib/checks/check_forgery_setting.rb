require 'checks/base_check'

#Checks that +protect_from_forgery+ is set in the ApplicationController
class CheckForgerySetting < BaseCheck
  Checks.add self

  def run_check
    app_controller = tracker.controllers[:ApplicationController]
    if tracker.config[:rails][:action_controller] and
      tracker.config[:rails][:action_controller][:allow_forgery_protection] == Sexp.new(:false)

      warn :controller => :ApplicationController,
        :warning_type => "Cross Site Request Forgery",
        :message => "Forgery protection is disabled", 
        :confidence => CONFIDENCE[:high]

    elsif app_controller and not app_controller[:options][:protect_from_forgery]

      warn :controller => :ApplicationController, 
        :warning_type => "Cross-Site Request Forgery", 
        :message => "'protect_from_forgery' should be called in ApplicationController", 
        :confidence => CONFIDENCE[:high]
    end
  end
end

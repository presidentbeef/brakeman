require 'brakeman/checks/base_check'

#Checks if default routes are allowed in routes.rb
class Brakeman::CheckDefaultRoutes < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for default routes"

  #Checks for :allow_all_actions globally and for individual routes
  #if it is not enabled globally.
  def run_check
    if tracker.routes[:allow_all_actions]
      #Default routes are enabled globally
      warn :warning_type => "Default Routes", 
        :warning_code => :all_default_routes,
        :message => "All public methods in controllers are available as actions in routes.rb",
        :line => tracker.routes[:allow_all_actions].line, 
        :confidence => CONFIDENCE[:high],
        :file => "#{tracker.options[:app_path]}/config/routes.rb"
    else #Report each controller separately
      Brakeman.debug "Checking each controller for default routes"

      tracker.routes.each do |name, actions|
        if actions.is_a? Array and actions[0] == :allow_all_actions
          warn :controller => name,
            :warning_type => "Default Routes", 
            :warning_code => :controller_default_routes,
            :message => "Any public method in #{name} can be used as an action.",
            :line => actions[1],
            :confidence => CONFIDENCE[:med],
            :file => "#{tracker.options[:app_path]}/config/routes.rb"
        end
      end
    end
  end
end

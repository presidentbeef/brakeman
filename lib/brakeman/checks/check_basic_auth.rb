require 'brakeman/checks/base_check'

#Checks if password is stored in controller
#when using http_basic_authenticate_with
#
#Only for Rails >= 3.1
class Brakeman::CheckBasicAuth < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for the use of http_basic_authenticate_with"

  def run_check
    return if version_between? "0.0.0", "3.0.99"

    controllers = tracker.controllers.select do |name, c|
      c[:options][:http_basic_authenticate_with]
    end

    Hash[controllers].each do |name, controller|
      controller[:options][:http_basic_authenticate_with].each do |call|

        if pass = get_password(call) and string? pass
          warn :controller => name,
              :warning_type => "Basic Auth", 
              :message => "Basic authentication password stored in source code",
              :code => call, 
              :confidence => 0

          break
        end
      end
    end
  end

  def get_password call
    arg = call.first_arg

    return false if arg.nil? or not hash? arg

    hash_access(arg, :password)
  end
end

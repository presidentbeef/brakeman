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
              :line => call.line,
              :code => call, 
              :confidence => 0

          break
        end
      end
    end
  end

  def get_password call
    args = call[3][1]

    return false if args.nil? or not hash? args

    hash_iterate(args) do |k, v|
      if symbol? k and k[1] == :password
        return v
      end
    end

    nil
  end
end

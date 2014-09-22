require 'brakeman/checks/base_check'

#At the moment, this looks for
#
#  skip_before_filter :verify_authenticity_token, :except => [...]
#
#which is essentially a blacklist approach (no actions are checked EXCEPT the
#ones listed) versus a whitelist approach (ONLY the actions listed will skip
#the check)
class Brakeman::CheckSkipBeforeFilter < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Warn when skipping CSRF or authentication checks by default"

  def run_check
    tracker.controllers.each do |name, controller|
      filter_skips = controller[:options].values_at(:skip_before_filter, :skip_filter, :skip_before_action, :skip_action_callback).compact.flatten(1)

      filter_skips.each do |filter|
        process_skip_filter filter, controller
      end
    end
  end

  def process_skip_filter filter, controller
    case skip_except_value filter
    when :verify_authenticity_token
      warn :class => controller[:name], #ugh this should be a controller warning, too
        :warning_type => "Cross-Site Request Forgery",
        :warning_code => :csrf_blacklist,
        :message => "Use whitelist (:only => [..]) when skipping CSRF check",
        :code => filter,
        :confidence => CONFIDENCE[:med],
        :file => controller[:files].first

    when :login_required, :authenticate_user!, :require_user
      warn :controller => controller[:name],
        :warning_code => :auth_blacklist,
        :warning_type => "Authentication",
        :message => "Use whitelist (:only => [..]) when skipping authentication",
        :code => filter,
        :confidence => CONFIDENCE[:med],
        :link => "authentication_whitelist",
        :file => controller[:files].first
    end
  end

  def skip_except_value filter
    return false unless call? filter

    first_arg = filter.first_arg
    last_arg = filter.last_arg

    if symbol? first_arg and hash? last_arg
      if hash_access(last_arg, :except)
        return first_arg.value
      end
    end

    false
  end
end

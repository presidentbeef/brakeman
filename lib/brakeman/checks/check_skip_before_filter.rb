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

  @description = "Warn when skipping CSRF check by default"

  def run_check
    tracker.controllers.each do |name, controller|
      if filter_skips = (controller[:options][:skip_before_filter] or controller[:options][:skip_filter])
        filter_skips.each do |filter|
          process_skip_filter filter, controller
        end
      end
    end
  end

  def process_skip_filter filter, controller
    if skip_verify_except? filter
      warn :class => controller[:name],
        :warning_type => "Cross-Site Request Forgery",
        :message => "Use whitelist (:only => [..]) when skipping CSRF check",
        :code => filter,
        :confidence => CONFIDENCE[:med]
    end
  end

  def skip_verify_except? filter
    return false unless call? filter

    first_arg = filter.first_arg
    last_arg = filter.last_arg

    if symbol? first_arg and first_arg.value == :verify_authenticity_token and hash? last_arg
      if hash_access(last_arg, :except)
        return true
      end
    end

    false
  end
end

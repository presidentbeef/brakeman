require 'brakeman/checks/base_check'

#Verify that checks external to the checks/ dir are added by the additional_checks_path options flag
class Brakeman::CheckExternalCheckTest < Brakeman::BaseCheck
  Brakeman::Checks.add_optional self

  @description = "An external check that does nothing, used for testing"

  def run_check
    tracker.find_call(target: nil, method: :call_shady_method).each do |result|
      if user_input = has_immediate_user_input?(result[:call].first_arg)
        warn result: result,
          warning_type: "Shady Call",
          warning_code: :custom_check,
          message: "Called something shady!",
          confidence: :high,
          user_input: user_input
      end
    end
  end
end

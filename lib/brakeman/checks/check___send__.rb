require 'brakeman/checks/base_check'

#Checks if user supplied data is passed to send
class Brakeman::CheckUnderscoreSend < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Check for unsafe use of Object#__send__"

  def run_check
    Brakeman.debug("Finding instances of #__send__")
    calls = tracker.find_call :method => :__send__

    calls.each do |call|
      process_result call
    end
  end

  def process_result result
    process_call_args result[:call]
    target = process result[:call].target

    if input = has_immediate_user_input?(result[:call].first_arg)
      warn :result => result,
        :warning_type => "Dangerous Send",
        :message => "User controlled method execution",
        :code => result[:call],
        :user_input => input.match,
        :confidence => CONFIDENCE[:high]
    end

    if input = has_immediate_user_input?(target)
      warn :result => result,
        :warning_type => "Dangerous Send",
        :message => "User defined target of method invocation",
        :code => result[:call],
        :user_input => input.match,
        :confidence => CONFIDENCE[:med]
    end
  end
end

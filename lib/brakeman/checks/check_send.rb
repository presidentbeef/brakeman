require 'brakeman/checks/base_check'

#Checks if user supplied data is passed to send
class Brakeman::CheckSend < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Check for unsafe use of Object#send"

  def run_check
    Brakeman.debug("Finding instances of #send")
    calls = tracker.find_call :methods => [:send, :try, :__send__, :public_send]

    calls.each do |call|
      process_result call
    end
  end

  def process_result result
    return if duplicate? result or result[:call].original_line
    add_result result

    process_call_args result[:call]
    target = process result[:call].target

    if input = has_immediate_user_input?(result[:call].first_arg)
      warn :result => result,
        :warning_type => "Dangerous Send",
        :warning_code => :dangerous_send,
        :message => "User controlled method execution",
        :code => result[:call],
        :user_input => input.match,
        :confidence => CONFIDENCE[:high]
    end
  end
end

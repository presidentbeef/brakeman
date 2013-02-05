require 'brakeman/checks/base_check'

#Checks if user supplied data is passed to send
class Brakeman::CheckTry < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Check for unsafe use of Object#try"

  def run_check
    Brakeman.debug("Finding instances of #try")
    calls = tracker.find_call :method => :try

    calls.each do |call|
      process_result call
    end
  end

  def process_result result
    process_call_args result[:call]
    target = process result[:call].target

    if input = has_immediate_user_input?(result[:call].first_arg)
      warn :result => result,
        :warning_type => "Dangerous Try",
        :message => "User controlled method execution",
        :code => result[:call],
        :user_input => input.match,
        :confidence => CONFIDENCE[:high]
    end

    if input = has_immediate_user_input?(target)
      warn :result => result,
        :warning_type => "Dangerous Try",
        :message => "User defined target of method invocation",
        :code => result[:call],
        :user_input => input.match,
        :confidence => CONFIDENCE[:med]
    end
  end
end

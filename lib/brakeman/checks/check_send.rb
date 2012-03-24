require 'brakeman/checks/base_check'

#Checks if user supplied data is passed to send
class Brakeman::CheckSend < Brakeman::BaseCheck
  Brakeman::Checks.add self

  def run_check
    Brakeman.debug("Finding instances of #send")
    calls = tracker.find_call :method => :send

    calls.each do |call|
      process_result call
    end
  end

  def process_result result
    args = process result[:call][3]
    target = process result[:call][1]

    if has_immediate_user_input? args[1]
      warn :result => result,
        :warning_type => "Dangerous use of send",
        :message => "User controlled method execution",
        :code => result[:call],
        :confidence => CONFIDENCE[:high]
    end

    if has_immediate_user_input?(target)
      warn :result => result,
        :warning_type => "Dangerous use of send",
        :message => "User defined target of method invocation",
        :code => result[:call],
        :confidence => CONFIDENCE[:med]
    end
  end
end
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
    if include_user_input? result[:call]
      warn :result => result,
        :warning_type => "Dangerous use of send",
        :message => "User input in call to send",
        :code => result[:call],
        :confidence => CONFIDENCE[:high]
    end
  end
end
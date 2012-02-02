require 'brakeman/checks/base_check'

#This check looks for calls to +eval+, +instance_eval+, etc. which include
#user input.
class Brakeman::CheckEvaluation < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Searches for evaluation of user input"

  #Process calls
  def run_check
    Brakeman.debug "Finding eval-like calls"
    calls = tracker.find_call :method => [:eval, :instance_eval, :class_eval, :module_eval]

    Brakeman.debug "Processing eval-like calls"
    calls.each do |call|
      process_result call
    end
  end

  #Warns if result includes user input
  def process_result result
    if include_user_input? result[:call]
      warn :result => result,
        :warning_type => "Dangerous Eval",
        :message => "User input in eval",
        :code => result[:call],
        :confidence => CONFIDENCE[:high]
    end
  end
end

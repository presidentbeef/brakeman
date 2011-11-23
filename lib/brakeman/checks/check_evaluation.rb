require 'brakeman/checks/base_check'

#This check looks for calls to +eval+, +instance_eval+, etc. which include
#user input.
class Brakeman::CheckEvaluation < Brakeman::BaseCheck
  Brakeman::Checks.add self

  #Process calls
  def run_check
    calls = tracker.find_call nil, [:eval, :instance_eval, :class_eval, :module_eval]

    calls.each do |call|
      process_result call
    end
  end

  #Warns if result includes user input
  def process_result result
    if include_user_input? result[-1]
      warn :result => result,
        :warning_type => "Dangerous Eval",
        :message => "User input in eval",
        :code => result[-1],
        :confidence => CONFIDENCE[:high]
    end
  end
end

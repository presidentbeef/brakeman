require 'brakeman/checks/base_check'

#This check looks for regexes that include user input.
class Brakeman::CheckRegexDoS < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Searches regexes including user input"

  #Process calls
  def run_check
    Brakeman.debug "Finding dynamic regexes"
    calls = tracker.find_call :method => [:brakeman_regex_interp]

    Brakeman.debug "Processing dynamic regexes"
    calls.each do |call|
      process_result call
    end
  end

  #Warns if regex includes user input
  def process_result result
    return if duplicate? result

    if input = include_user_input?(result[:call])
      warn :result => result,
        :warning_type => "Denial of Service",
        :warning_code => :regex_dos,
        :message => "User input from #{friendly_type_of input} in regex",
        :user_input => input.match,
        :confidence => CONFIDENCE[:high]
    end
  end
end

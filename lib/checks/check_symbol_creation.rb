require 'checks/base_check'
require 'processors/lib/find_call'

#If an application turns user input into Symbols, there is a possiblity
#of DoS by using up all the memory.
class CheckSymbolCreation < BaseCheck
  Checks.add self

  def run_check
    calls = tracker.find_call nil, :to_sym

    calls.each do |result|
      process_call_to_sym result
    end
  end

  #Check calls to .to_sym which have user input as a target.
  def process_call_to_sym exp
    call = exp[-1]
    confidence = nil

    type, = has_immediate_user_input? call[1]

    if type
      confidence = CONFIDENCE[:high]
    elsif match = has_immediate_model?(call[1])
      type = :model
      confidence = CONFIDENCE[:high]
    elsif type = include_user_input?(call[1])
      confidence = CONFIDENCE[:med]
    end

    if type and not duplicate? exp
      add_result exp

      if res == :model
        message = "Symbol created from database value"
      else
        message = "Symbol created from user input"
      end

      warn :result => exp,
        :warning_type => "Symbol Creation",
        :message => message,
        :line => call.line,
        :code => call,
        :confidence => CONFIDENCE[:med]
    end

    exp

  end

end

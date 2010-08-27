require 'checks/base_check'
require 'processors/lib/find_call'

#This check looks for calls to +send()+ which use user input
#for or in the method name.
#
#For example:
#
#  some_object.send(params[:input], "hello")
#
#This is dangerous for (at least) two reasons. First, the user is controlling
#what method is being called, which cannot be good. Secondly, the method
#name will be converted to a Symbol, which is never garbage collected. This
#could possibly lead to DoS attacks by using up memory.
class CheckSend < BaseCheck
  Checks.add self

  #Check calls to +send+ and +__send__+
  def run_check
    calls = tracker.find_call nil, [:send, :__send__]

    calls.each do |result|
      process result
    end
  end

  #Check instances of +send+ which have user input in the method name
  def process_result exp
    call = exp[-1]
    method_name = process call[3][1]
    message = nil
    confidence = nil

    type, = has_immediate_user_input? method_name
    
    if type
      confidence = CONFIDENCE[:high]
    elsif match = has_immediate_model?(method_name)
      type = :model
      confidence = CONFIDENCE[:high]
    elsif type = include_user_input?(method_name)
      confidence = CONFIDENCE[:med]
    end

    if type == :model
      message = "Database value used to generate method name"
    elsif type
      message = "User input used to generate method name"
    end

    if message and confidence and not duplicate? call
      add_result call

      warn :result => exp,
        :warning_type => "Object#send", 
        :message => message,
        :line => call.line,
        :code => call,
        :confidence => confidence
    end

    exp
  end
end

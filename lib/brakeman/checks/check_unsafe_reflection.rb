require 'brakeman/checks/base_check'

# Checks for string interpolation and parameters in calls to
# String#constantize, String#safe_constantize, Module#const_get and Module#qualified_const_get.
#
# Exploit examples at: http://blog.conviso.com.br/2013/02/exploiting-unsafe-reflection-in.html
class Brakeman::CheckUnsafeReflection < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for Unsafe Reflection"

  def run_check
    reflection_methods = [:constantize, :safe_constantize, :const_get, :qualified_const_get]

    tracker.find_call(:methods => reflection_methods, :nested => true).each do |result|
      check_unsafe_reflection result
    end
  end

  def check_unsafe_reflection result
    return if duplicate? result
    add_result result

    call = result[:call] 
    method = call.method

    case method
    when :constantize, :safe_constantize
      arg = call.target
    else
      arg = call.first_arg
    end

    if input = has_immediate_user_input?(arg)
      confidence = CONFIDENCE[:high]
    elsif input = include_user_input?(arg)
      confidence = CONFIDENCE[:med]
    end

    if confidence
      message = "Unsafe Reflection method #{method} called with #{friendly_type_of input}"

      warn :result => result,
        :warning_type => "Remote Code Execution",
        :warning_code => :unsafe_constantize,
        :message => message,
        :user_input => input.match,
        :confidence => confidence
    end
  end
end

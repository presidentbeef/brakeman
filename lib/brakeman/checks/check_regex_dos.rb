require 'brakeman/checks/base_check'

#This check looks for regexes that include user input.
class Brakeman::CheckRegexDoS < Brakeman::BaseCheck
  Brakeman::Checks.add self

  ESCAPES = {
    s(:const, :Regexp) => [
      :escape,
      :quote
    ]
  }

  COERCES_STRING_TO_REGEX = [
    :match,
    :match?
  ]

  @description = "Searches regexes and coerced regexes including user input"

  #Process calls
  def run_check
    Brakeman.debug "Finding dynamic regexes"
    calls = tracker.find_call :method => [:brakeman_regex_interp]
    COERCES_STRING_TO_REGEX.each do |coercion_method|
      calls.concat tracker.find_call(:method => [coercion_method]).select { |call| string?(call[:target]) }
    end

    Brakeman.debug "Processing dynamic regexes"
    calls.each do |call|
      process_result call
    end
  end

  #Warns if regex includes user input
  def process_result result
    return unless original? result

    call = result[:call]
    components = call.sexp_body

    components.any? do |component|
      next unless sexp? component

      if match = has_immediate_user_input?(component)
        confidence = :high
      elsif match = has_immediate_model?(component)
        match = Match.new(:model, match)
        confidence = :medium
      elsif match = include_user_input?(component)
        confidence = :weak
      end

      if match
        if result[:method] == :brakeman_regex_interp
          message = msg(msg_input(match), " used in regular expression")
        else
          message = msg(msg_input(match), " used in string to regular expression coercion by ", msg_code(call.method), " method")
        end

        warn :result => result,
          :warning_type => "Denial of Service",
          :warning_code => :regex_dos,
          :message => message,
          :confidence => confidence,
          :user_input => match,
          :cwe_id => [20, 185]
      end
    end
  end

  def process_call(exp)
    if escape_methods = ESCAPES[exp.target]
      if escape_methods.include? exp.method
        return exp
      end
    end

    super
  end
end

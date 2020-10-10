require 'brakeman/checks/base_check'

class Brakeman::CheckUnsafeReflectionMethods < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for unsafe reflection to access methods"

  def run_check
    check_method
  end

  def check_method
    tracker.find_call(method: :method, nested: true).each do |result|
      argument = result[:call].first_arg

      if include_user_input? argument
        warn_unsafe_reflection(result, argument)
      end
    end
  end

  def warn_unsafe_reflection result, input
    return unless original? result
    method = result[:call].method

    confidence = :high

    if confidence
      message = msg("Unsafe reflection method ", msg_code(method), " called with ", msg_input(input))

      warn :result => result,
        :warning_type => "Remote Code Execution",
        :warning_code => :unsafe_method_reflection,
        :message => message,
        :user_input => input,
        :confidence => confidence
    end
  end
end

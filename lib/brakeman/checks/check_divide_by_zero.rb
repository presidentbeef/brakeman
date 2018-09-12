require 'brakeman/checks/base_check'

class Brakeman::CheckDivideByZero < Brakeman::BaseCheck
  Brakeman::Checks.add_optional self

  @description = "Warns on potential division by zero"

  def run_check
    tracker.find_call(:methods => [:/, :%]).each do |result|
      check_division result
    end
  end

  def check_division result
    return unless original? result

    call = result[:call]

    denominator = call.first_arg

    if possible_zero? denominator
      numerator = call.target

      if string? numerator
        return # formatting, not division
      elsif number? numerator
        if numerator.value.is_a? Float
          return # 0.0 / 0 is NaN and 1.0 / 0 is Infinity
        else
          confidence = :medium
        end
      else
        confidence = :weak
      end

      warn :result => result,
        :warning_type => "Divide by Zero",
        :warning_code => :divide_by_zero,
        :message => "Potential division by zero",
        :confidence => confidence,
        :user_input => denominator
    end
  end

  def possible_zero? exp
    if number? exp and exp.value.is_a? Integer and exp.value == 0
      true
    elsif node_type? exp, :or
      possible_zero? exp.lhs or
        possible_zero? exp.rhs
    else
      false
    end
  end
end

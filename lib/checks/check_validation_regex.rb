require 'checks/base_check'

#Reports any calls to +validates_format_of+ which do not use +\A+ and +\z+
#as anchors in the given regular expression.
#
#For example:
#
# #Allows anything after new line
# validates_format_of :user_name, :with => /^\w+$/
class CheckValidationRegex < BaseCheck
  Checks.add self

  WITH = Sexp.new(:lit, :with)

  def run_check
    tracker.models.each do |name, model|
      @current_model = name
      format_validations = model[:options][:validates_format_of]
      if format_validations
        format_validations.each do |v|
          process_validator v
        end
      end
    end
  end

  #Check validates_format_of
  def process_validator validator
    hash_iterate(validator[-1]) do |key, value|
      if key == WITH
        check_regex value, validator
      end
    end
  end

  #Issue warning if the regular expression does not use
  #+\A+ and +\z+
  def check_regex value, validator
    return unless regexp? value

    regex = value[1].inspect
    if regex =~ /[^\A].*[^\z]\/(m|i|x|n|e|u|s|o)*\z/
      warn :model => @current_model,
        :warning_type => "Format Validation", 
        :message => "Insufficient validation for '#{get_name validator}' using #{value[1].inspect}. Use \\A and \\z as anchors",
        :line => value.line,
        :confidence => CONFIDENCE[:high] 
    end
  end

  #Get the name of the attribute being validated.
  def get_name validator
    name = validator[1]
    if sexp? name
      name[1]
    else
      name
    end
  end
end

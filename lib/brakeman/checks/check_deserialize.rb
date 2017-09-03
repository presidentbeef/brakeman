require 'brakeman/checks/base_check'

class Brakeman::CheckDeserialize < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for unsafe deserialization of objects"

  def run_check
    check_yaml
    check_csv
    check_marshal
  end

  def check_yaml
    check_methods :YAML, :load, :load_documents, :load_stream, :parse_documents, :parse_stream
  end

  def check_csv
    check_methods :CSV, :load
  end

  def check_marshal
    check_methods :Marshal, :load, :restore
  end

  def check_methods target, *methods
    tracker.find_call(:target => target, :methods => methods ).each do |result|
      check_deserialize result, target
    end
  end

  def check_deserialize result, target, arg = nil
    return unless original? result

    arg ||= result[:call].first_arg
    method = result[:call].method

    if input = has_immediate_user_input?(arg)
      confidence = :high
    elsif input = include_user_input?(arg)
      confidence = :medium
    end

    if confidence
      message = "#{target}.#{method} called with #{friendly_type_of input}"

      warn :result => result,
        :warning_type => "Remote Code Execution",
        :warning_code => :unsafe_deserialize,
        :message => message,
        :user_input => input,
        :confidence => confidence,
        :link_path => "unsafe_deserialization"
    end
  end
end

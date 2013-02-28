require 'brakeman/checks/base_check'

#YAML.load can be used for remote code execution
class Brakeman::CheckYAMLLoad < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for uses of YAML.load"

  def run_check
    yaml_methods = [:load, :load_documents, :load_stream, :parse_documents, :parse_stream]

    tracker.find_call(:target => :YAML, :methods => yaml_methods ).each do |result|
      check_yaml_load result
    end
  end

  def check_yaml_load result
    return if duplicate? result
    add_result result

    arg = result[:call].first_arg
    method = result[:call].method

    if input = has_immediate_user_input?(arg)
      confidence = CONFIDENCE[:high]
    elsif input = include_user_input?(arg)
      confidence = CONFIDENCE[:med]
    end

    if confidence
      input_type = case input.type
                   when :params
                     "parameter value"
                   when :cookies
                     "cookies value"
                   when :request
                     "request value"
                   when :model
                     "model attribute"
                   else
                     "user input"
                   end

      message = "YAML.#{method} called with #{input_type}"

      warn :result => result,
        :warning_type => "Remote Code Execution",
        :warning_code => :unsafe_deserialize,
        :message => message,
        :user_input => input.match,
        :confidence => confidence,
        :link_path => "remote_code_execution_yaml_load"
    end
  end
end

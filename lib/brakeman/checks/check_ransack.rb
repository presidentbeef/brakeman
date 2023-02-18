require 'brakeman/checks/base_check'

class Brakeman::CheckRansack < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Check for unsafe use of Ransack gem"

  def run_check
    calls = tracker.find_call method: :ransack

    calls.each do |call|
      process_result call
    end
  end

  def process_result result
    return unless original? result

    input = result[:call].first_arg

    if params? input
      warn result: result,
        warning_type: 'Missing Authorization',
        warning_code: :ransack,
        message: msg('Unrestricted search using ', msg_code('ransack'), ' method'),
        user_input: input,
        confidence: :high,
        cwe_id: [639]
    end
  end
end

require 'brakeman/checks/base_check'

class Brakeman::CheckXssInFlash < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Check XSS attacks via the flash object"

  def run_check
    tracker.find_call(:method => :[]=, :target => :flash).each do |result|
      process_result result
    end
  end

  def process_result result
    return unless original? result

    message = result[:call].second_arg

    if input = include_user_input?(message)
      warn :result => result,
        :warning_type => "XSS in flash",
        :warning_code => :xss_in_flash,
        :message => msg(msg_input(input), " is being used in the flash object"),
        :user_input => input,
        :confidence => :high
    end
  end
end

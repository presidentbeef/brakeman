require 'brakeman/checks/base_check'

class Brakeman::CheckNumberToCurrency < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for number_to_currency XSS vulnerability in certain versions"

  def run_check
    if (version_between? "2.0.0", "3.2.15" or version_between? "4.0.0", "4.0.1")
      check_number_to_currency_usage

      generic_warning unless @found_any
    end
  end

  def generic_warning
    message = "Rails #{tracker.config[:rails_version]} has a vulnerability in number_to_currency (CVE-2013-6415). Upgrade to Rails version "

    if version_between? "2.3.0", "3.2.15"
      message << "3.2.16"
    else
      message << "4.0.2"
    end

    warn :warning_type => "Cross Site Scripting",
      :warning_code => :CVE_2013_6415,
      :message => message,
      :confidence => CONFIDENCE[:med],
      :file => gemfile_or_environment,
      :link_path => "https://groups.google.com/d/msg/ruby-security-ann/9WiRn2nhfq0/2K2KRB4LwCMJ"
  end

  def check_number_to_currency_usage
    tracker.find_call(:target => false, :method => :number_to_currency).each do |result|
      arg = result[:call].second_arg
      next unless arg

      if match = (has_immediate_user_input? arg or has_immediate_model? arg)
        match = match.match if match.is_a? Match
        @found_any = true
        warn_on_number_to_currency result, match
      end
    end
  end

  def warn_on_number_to_currency result, match
    warn :result => result,
      :warning_type => "Cross Site Scripting",
      :warning_code => :CVE_2013_6415_call,
      :message => "Currency value in number_to_currency is not safe in Rails #{@tracker.config[:rails_version]}",
      :confidence => CONFIDENCE[:high],
      :link_path => "https://groups.google.com/d/msg/ruby-security-ann/9WiRn2nhfq0/2K2KRB4LwCMJ",
      :user_input => match
  end
end

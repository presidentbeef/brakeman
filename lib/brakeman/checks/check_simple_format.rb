require 'brakeman/checks/base_check'

class Brakeman::CheckSimpleFormat < Brakeman::CheckCrossSiteScripting
  Brakeman::Checks.add self

  @description = "Checks for simple_format XSS vulnerability (CVE-2013-6416) in certain versions"

  def run_check
    if version_between? "4.0.0", "4.0.1"
      @inspect_arguments = true
      @ignore_methods = Set[:h, :escapeHTML]

      check_simple_format_usage
      generic_warning unless @found_any
    end
  end

  def generic_warning
    message = "Rails #{tracker.config[:rails_version]} has a vulnerability in simple_format (CVE-2013-6416). Upgrade to Rails version 4.0.2"

    warn :warning_type => "Cross-Site Scripting",
      :warning_code => :CVE_2013_6416,
      :message => message,
      :confidence => CONFIDENCE[:med],
      :gem_info => gemfile_or_environment,
      :link_path => "https://groups.google.com/d/msg/ruby-security-ann/5ZI1-H5OoIM/ZNq4FoR2GnIJ"
  end

  def check_simple_format_usage
    tracker.find_call(:target => false, :method => :simple_format).each do |result|
      @matched = false
      process_call result[:call]
      if @matched
        warn_on_simple_format result, @matched
      end
    end
  end

  def process_call exp
    @mark = true
    actually_process_call exp
    exp
  end

  def warn_on_simple_format result, match
    return if duplicate? result
    add_result result

    @found_any = true

    warn :result => result,
      :warning_type => "Cross-Site Scripting",
      :warning_code => :CVE_2013_6416_call,
      :message => "Values passed to simple_format are not safe in Rails #{@tracker.config[:rails_version]}",
      :confidence => CONFIDENCE[:high],
      :gem_info => gemfile_or_environment,
      :link_path => "https://groups.google.com/d/msg/ruby-security-ann/5ZI1-H5OoIM/ZNq4FoR2GnIJ",
      :user_input => match.match
  end
end

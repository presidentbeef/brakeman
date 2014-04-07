require 'brakeman/checks/base_check'

class Brakeman::CheckSymbolDoS < Brakeman::BaseCheck
  Brakeman::Checks.add self

  UNSAFE_METHODS = [:to_sym, :literal_to_sym, :intern, :symbolize_keys, :symbolize_keys!]

  @description = "Checks for versions with ActiveRecord symbol denial of service, or code with a similar vulnerability"

  def run_check
    fix_version = case
      when version_between?('2.0.0', '2.3.17')
        '2.3.18'
      when version_between?('3.1.0', '3.1.11')
        '3.1.12'
      when version_between?('3.2.0', '3.2.12')
        '3.2.13'
      else
        nil
      end

    if fix_version && active_record_models.any?
      warn :warning_type => "Denial of Service",
        :warning_code => :CVE_2013_1854,
        :message => "Rails #{tracker.config[:rails_version]} has a denial of service vulnerability in ActiveRecord: upgrade to #{fix_version} or patch",
        :confidence => CONFIDENCE[:med],
        :file => gemfile_or_environment,
        :link => "https://groups.google.com/d/msg/rubyonrails-security/jgJ4cjjS8FE/BGbHRxnDRTIJ"
    end

    tracker.find_call(:methods => UNSAFE_METHODS, :nested => true).each do |result|
      check_unsafe_symbol_creation(result)
    end

  end

  def check_unsafe_symbol_creation result
    return if duplicate? result or result[:call].original_line

    add_result result

    call = result[:call]

    if result[:method] == :literal_to_sym
      args = call.select { |e| sexp? e }
    else
      args = [call.target]
    end

    if input = args.map{ |arg| has_immediate_user_input?(arg) }.compact.first
      confidence = CONFIDENCE[:high]
    elsif input = args.map{ |arg| include_user_input?(arg) }.compact.first
      confidence = CONFIDENCE[:med]
    end

    if confidence
      message = "Symbol conversion from unsafe string (#{friendly_type_of input})"

      warn :result => result,
        :warning_type => "Denial of Service",
        :warning_code => :unsafe_symbol_creation,
        :message => message,
        :user_input => input.match,
        :confidence => confidence
    end

  end

end

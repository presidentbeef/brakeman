require 'brakeman/checks/base_check'

# Checks if verify_mode= is called with OpenSSL::SSL::VERIFY_NONE

class Brakeman::CheckSSLVerify < Brakeman::BaseCheck
  Brakeman::Checks.add self

  SSL_VERIFY_NONE = s(:colon2, s(:colon2, s(:const, :OpenSSL), :SSL), :VERIFY_NONE)

  @description = "Checks for OpenSSL::SSL::VERIFY_NONE"

  def run_check
    check_open_ssl_verify_none
  end

  def check_open_ssl_verify_none
    tracker.find_call(:method => :verify_mode=).each {|call| process_result(call)}
  end

  def process_result(result)
    return if duplicate?(result)
    if result[:call].last_arg == SSL_VERIFY_NONE
      add_result result
      warn :result => result,
        :warning_type => "SSL Verification Bypass",
        :warning_code => :ssl_verification_bypass,
        :message => "SSL certificate verification was bypassed",
        :confidence => CONFIDENCE[:high]
    end
  end
end

require 'brakeman/checks/base_check'

class Brakeman::CheckWeakRSAKey < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for weak uses RSA keys"

  def run_check
    tracker.find_call(targets: [:'OpenSSL::PKey::RSA'], method: [:new, :generate], nested: true).each do |result|
      check_key_size(result)
    end

    tracker.find_call(targets: [:'OpenSSL::PKey::RSA.new'], method: [:public_encrypt, :public_decrypt, :private_encrypt, :private_decrypt], nested: true).each do |result|
      check_padding(result)
    end
  end

  def check_key_size result
    return unless original? result

    first_arg = result[:call].first_arg

    if number? first_arg
      key_size = first_arg.value

      if key_size < 1024
        confidence = :high
        message = msg("RSA key with size ", msg_code(key_size.to_s), " is considered very weak. Use at least 2048 bit key size")
      elsif key_size < 2048
        confidence = :medium
        message = msg("RSA key with size ", msg_code(key_size.to_s), " is considered weak. Use at least 2048 bit key size")
      else
        return
      end

      warn result: result,
        warning_type: "Weak Cryptography",
        warning_code: :small_rsa_key_size,
        message: message,
        confidence: confidence,
        user_input: first_arg,
        cwe_id: [326]
    end
  end

  PKCS1_PADDING = s(:colon2, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :PKCS1_PADDING).freeze
  NO_PADDING = s(:colon2, s(:colon2, s(:colon2, s(:const, :OpenSSL), :PKey), :RSA), :NO_PADDING).freeze

  def check_padding result
    return unless original? result

    padding_arg = result[:call].second_arg

    case padding_arg
    when PKCS1_PADDING, nil
      message = "Use of padding mode PKCS1 (default if not specified), which is known to be insecure"

      warn result: result,
        warning_type: "Weak Cryptography",
        warning_code: :insecure_rsa_padding_mode,
        message: message,
        confidence: :high,
        user_input: padding_arg,
        cwe_id: [780]
    when NO_PADDING
      message = "No padding mode used for RSA key. A safe padding mode should be specified for RSA keys"

      warn result: result,
        warning_type: "Weak Cryptography",
        warning_code: :missing_rsa_padding_mode,
        message: message,
        confidence: :high,
        user_input: padding_arg,
        cwe_id: [780]
    end
  end
end

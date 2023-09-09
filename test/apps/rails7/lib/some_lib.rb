class SomeLib
  def some_rsa_encrypting
    public_key = OpenSSL::PKey::RSA.new("grab the public 4096 bit key")
    encrypted = Base64.encode64(public_key.public_encrypt(payload.to_json)) # Weak padding mode default
    public_key.private_decrypt(Base64.decode64(encrypted)) # Weak padding mode default
  end

  def some_more_rsa_padding_modes
    public_key = OpenSSL::PKey::RSA.new("grab the public 4096 bit key")
    public_key.public_decrypt(data, OpenSSL::PKey::RSA::PKCS1_PADDING)
    public_key.private_encrypt(data, OpenSSL::PKey::RSA::NO_PADDING)
    public_key.private_encrypt(data, OpenSSL::PKey::RSA::SSLV23_PADDING)
  end

  def small_rsa_keys 
    OpenSSL::PKey::RSA.generate(512) # Very weak
    OpenSSL::PKey::RSA.new(1024) # Weak
    OpenSSL::PKey::RSA.new(2048) # Okay
  end

  def pky_api
    weak_rsa = OpenSSL::PKey.generate_key("rsa", rsa_keygen_bits: 1024) # Medium warning about key size
    weak_encrypted = weak_rsa.encrypt("data", "rsa_padding_mode" => "pkcs1")
    weak_encrypted = weak_rsa.decrypt("data", "rsa_padding_mode" => "oaep")
    weak_signature_digest = weak_rsa.sign("SHA256", "data", rsa_padding_mode: "PKCS1")
    weak_rsa.verify("SHA256", "data", rsa_padding_mode: "none")
    weak_rsa.sign_raw(nil, "data", rsa_padding_mode: "none")
    weak_rsa.verify_raw(nil, "data", rsa_padding_mode: "none")
    weak_rsa.encrypt("data") # default is also pkcs1
  end

  class << self
    def self.x
      # why
    end
  end
end

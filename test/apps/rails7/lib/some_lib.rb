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
end

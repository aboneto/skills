require "openssl"
require "json"

class ReasoningMessage
  attr_reader :id, :content, :encrypted_value

  def initialize(id:, content:, encryption_key:)
    @id = id
    @content = content
    @encrypted_value = encrypt(content, encryption_key)
  end

  def to_h
    { id: @id, content: @content, encrypted_value: @encrypted_value }
  end

  def to_json(*args)
    to_h.to_json(*args)
  end

  private

  def encrypt(plaintext, key)
    cipher = OpenSSL::Cipher.new("aes-256-gcm")
    cipher.encrypt
    cipher.key = key
    iv = cipher.random_iv

    ciphertext = cipher.update(plaintext) + cipher.final
    tag = cipher.auth_tag

    { iv: Base64.strict_encode64(iv),
      ciphertext: Base64.strict_encode64(ciphertext),
      tag: Base64.strict_encode64(tag) }.to_json
  end
end

require "ag_ui_protocol"

reasoning = AgUiProtocol::Core::Types::ReasoningMessage.new(
  id: "reason_enc_1",
  content: nil,
  encrypted_value: "AES-256-GCM-encrypted-base64-string=="
)

puts reasoning.to_json

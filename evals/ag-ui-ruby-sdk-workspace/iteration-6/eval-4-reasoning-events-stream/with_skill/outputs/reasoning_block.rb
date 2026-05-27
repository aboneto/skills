require "securerandom"
require "stringio"
require "ag_ui_protocol"

encoder = AgUiProtocol::Encoder::EventEncoder.new
stream = StringIO.new
stream.singleton_class.define_method(:flush) { rewind if respond_to?(:rewind) }

reasoning_id = "reason_#{SecureRandom.hex(8)}"
message_id = "reason_msg_#{SecureRandom.hex(8)}"

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::ReasoningStartEvent.new(
    message_id: reasoning_id
  )
))

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::ReasoningMessageStartEvent.new(
    message_id: message_id
  )
))

chunks = [
  "I need to analyze the user's query step by step.",
  "First, I'll identify the key requirements and constraints.",
  "Then, I'll evaluate possible approaches and their trade-offs.",
  "Finally, I'll synthesize the optimal solution."
]

chunks.each do |chunk|
  stream.write(encoder.encode(
    AgUiProtocol::Core::Events::ReasoningMessageContentEvent.new(
      message_id: message_id,
      delta: chunk
    )
  ))
end

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::ReasoningMessageEndEvent.new(
    message_id: message_id
  )
))

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::ReasoningEncryptedValueEvent.new(
    subtype: "tool-call",
    entity_id: "tc_#{SecureRandom.hex(4)}",
    encrypted_value: Base64.strict_encode64("sensitive_reasoning_content")
  )
))

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::ReasoningEndEvent.new(
    message_id: reasoning_id
  )
))

stream.rewind
puts stream.read

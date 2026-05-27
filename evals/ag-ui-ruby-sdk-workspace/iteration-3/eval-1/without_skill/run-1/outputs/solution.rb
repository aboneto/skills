# frozen_string_literal: true

require 'ag-ui_protocol'

text_content = AgUiProtocol::TextInputContent.new(
  text: "Hello, here is an image and a document attached."
)

image_content = AgUiProtocol::BinaryInputContent.new(
  data: Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="),
  media_type: "image/png",
  filename: "example.png"
)

doc_content = AgUiProtocol::BinaryInputContent.new(
  data: File.read("document.pdf"),
  media_type: "application/pdf",
  filename: "document.pdf"
)

user_message = AgUiProtocol::UserMessage.new(
  content: [text_content, image_content, doc_content]
)

user_message.id = "msg_001"
user_message.timestamp = Time.now.utc.iso8601

agent_context = AgUiProtocol::AgentContext.new(
  agent_id: "document-processor",
  session_id: "session_abc123"
)

agent_context.parameters["temperature"] = 0.7
agent_context.parameters["max_tokens"] = 1000
agent_context.parameters["language"] = "en"

stream_options = AgUiProtocol::StreamOptions.new(
  stream: true,
  streaming_updates: true
)

run_agent_input = AgUiProtocol::RunAgentInput.new(
  message: user_message,
  agent_context: agent_context,
  stream_options: stream_options
)

puts "RunAgentInput created successfully!"
puts run_agent_input.to_json

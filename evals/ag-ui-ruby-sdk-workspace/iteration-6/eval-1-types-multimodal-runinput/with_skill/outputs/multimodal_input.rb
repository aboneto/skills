# multimodal_input.rb

require "securerandom"

user_message = AgUiProtocol::Core::Types::UserMessage.new(
  id: SecureRandom.uuid,
  content: [
    AgUiProtocol::Core::Types::TextInputContent.new(
      text: "Describe what you see in this image and summarize the document"
    ),
    AgUiProtocol::Core::Types::BinaryInputContent.new(
      mime_type: "image/png",
      url: "https://example.com/diagram.png"
    ),
    AgUiProtocol::Core::Types::BinaryInputContent.new(
      mime_type: "application/pdf",
      id: "uploaded_report_001"
    )
  ]
)

developer_message = AgUiProtocol::Core::Types::DeveloperMessage.new(
  id: SecureRandom.uuid,
  content: "You are a helpful assistant that can analyze images and documents."
)

web_search_tool = AgUiProtocol::Core::Types::Tool.new(
  name: "web_search",
  description: "Search the web for current information",
  parameters: {
    type: "object",
    properties: {
      query: { type: "string", description: "The search query" }
    },
    required: ["query"]
  }
)

locale_context = AgUiProtocol::Core::Types::Context.new(
  description: "User locale",
  value: "en-US"
)

input = AgUiProtocol::Core::Types::RunAgentInput.new(
  thread_id: "thread_#{SecureRandom.uuid}",
  run_id: "run_#{SecureRandom.uuid}",
  state: {},
  messages: [developer_message, user_message],
  tools: [web_search_tool],
  context: [locale_context],
  forwarded_props: { source: "chat_ui" }
)

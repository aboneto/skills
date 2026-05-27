require "ag_ui_protocol/core/types"

text_content = AgUiProtocol::Core::Types::TextInputContent.new(
  text: "What breed is this cat?"
)

image_content = AgUiProtocol::Core::Types::BinaryInputContent.new(
  mime_type: "image/jpeg",
  url: "https://example.com/cat.jpg"
)

user_message = AgUiProtocol::Core::Types::UserMessage.new(
  id: "user_1",
  content: [text_content, image_content]
)

assistant_message = AgUiProtocol::Core::Types::AssistantMessage.new(
  id: "asst_1",
  content: "Analyzing the image of the cat."
)

web_search_tool = AgUiProtocol::Core::Types::Tool.new(
  name: "web_search",
  description: "Search the web for information",
  parameters: {
    "type" => "object",
    "properties" => {
      "q" => { "type" => "string", "description" => "The search query" }
    },
    "required" => ["q"]
  }
)

locale_context = AgUiProtocol::Core::Types::Context.new(
  description: "User locale",
  value: "en-US"
)

input = AgUiProtocol::Core::Types::RunAgentInput.new(
  thread_id: "thread_42",
  run_id: "run_99",
  state: {},
  messages: [user_message, assistant_message],
  tools: [web_search_tool],
  context: [locale_context],
  forwarded_props: {}
)

puts input.to_json

require "ag-ui-protocol"

thread_id = "thread_#{SecureRandom.uuid}"
run_id = "run_#{SecureRandom.uuid}"

text_content = AgUiProtocol::Core::Types::TextInputContent.new(
  text: "Please analyze this image and tell me what you see."
)

binary_content = AgUiProtocol::Core::Types::BinaryInputContent.new(
  mime_type: "image/png",
  url: "https://example.com/diagram.png"
)

multimodal_message = AgUiProtocol::Core::Types::UserMessage.new(
  id: "msg_#{SecureRandom.uuid}",
  content: [text_content, binary_content]
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

run_agent_input = AgUiProtocol::Core::Types::RunAgentInput.new(
  thread_id: thread_id,
  run_id: run_id,
  state: {},
  messages: [multimodal_message],
  tools: [web_search_tool],
  context: [locale_context],
  forwarded_props: {}
)

puts "RunAgentInput created successfully!"
puts "Thread ID: #{run_agent_input.thread_id}"
puts "Run ID: #{run_agent_input.run_id}"
puts "Messages count: #{run_agent_input.messages.length}"
puts "Message 0 content type: #{run_agent_input.messages[0].content[0].class.name}"
puts "Message 0 binary type: #{run_agent_input.messages[0].content[1].class.name}"
puts "Tools count: #{run_agent_input.tools.length}"
puts "Context count: #{run_agent_input.context.length}"
puts "\nFull JSON:"
puts run_agent_input.to_json
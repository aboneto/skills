```ruby
#!/usr/bin/env ruby

require "ag-ui-protocol"

# Create a multimodal UserMessage with text and image content
user_message = AgUiProtocol::Core::Types::UserMessage.new(
  id: "msg_001",
  content: [
    AgUiProtocol::Core::Types::TextInputContent.new(
      text: "What can you tell me about this image?"
    ),
    AgUiProtocol::Core::Types::BinaryInputContent.new(
      mime_type: "image/png",
      url: "https://example.com/sample.png"
    )
  ]
)

# Define a tool for the agent
web_search_tool = AgUiProtocol::Core::Types::Tool.new(
  name: "web_search",
  description: "Searches the web for information",
  parameters: {
    type: "object",
    properties: {
      query: { type: "string" }
    },
    required: ["query"]
  }
)

# Define context
locale_ctx = AgUiProtocol::Core::Types::Context.new(
  description: "User locale",
  value: "en-US"
)

# Construct the complete RunAgentInput
run_input = AgUiProtocol::Core::Types::RunAgentInput.new(
  thread_id: "thread_abc123",
  run_id: "run_xyz789",
  state: {},
  messages: [user_message],
  tools: [web_search_tool],
  context: [locale_ctx],
  forwarded_props: {}
)

puts "RunAgentInput created successfully:"
puts "Thread ID: #{run_input.thread_id}"
puts "Run ID: #{run_input.run_id}"
puts "Messages: #{run_input.messages.length}"
puts "Tools: #{run_input.tools.length}"
puts "Context: #{run_input.context.length}"
```

#!/usr/bin/env ruby

require "ag-ui-protocol"
require "json"
require "securerandom"

def build_multimodal_user_message
  AgUiProtocol::Core::Types::UserMessage.new(
    id: SecureRandom.uuid,
    content: [
      AgUiProtocol::Core::Types::TextInputContent.new(
        text: "Please analyze this image and provide a summary."
      ),
      AgUiProtocol::Core::Types::BinaryInputContent.new(
        mime_type: "image/png",
        url: "https://example.com/diagram.png",
        filename: "diagram.png"
      )
    ]
  )
end

def build_tools
  web_search_tool = AgUiProtocol::Core::Types::Tool.new(
    name: "web_search",
    description: "Search the web for information",
    parameters: {
      "type" => "object",
      "properties" => {
        "q" => { "type" => "string", "description" => "The search query" },
        "limit" => { "type" => "integer", "description" => "Max results", "default" => 10 }
      },
      "required" => ["q"]
    }
  )

  calculator_tool = AgUiProtocol::Core::Types::Tool.new(
    name: "calculator",
    description: "Perform arithmetic calculations",
    parameters: {
      "type" => "object",
      "properties" => {
        "expression" => { "type" => "string", "description" => "Math expression to evaluate" }
      },
      "required" => ["expression"]
    }
  )

  [web_search_tool, calculator_tool]
end

def build_context
  locale_context = AgUiProtocol::Core::Types::Context.new(
    description: "User locale",
    value: "en-US"
  )

  timezone_context = AgUiProtocol::Core::Types::Context.new(
    description: "User timezone",
    value: "America/New_York"
  )

  [locale_context, timezone_context]
end

def build_assistant_message
  AgUiProtocol::Core::Types::AssistantMessage.new(
    id: SecureRandom.uuid,
    content: "I'll help you analyze that image. Let me search for relevant context first."
  )
end

def main
  thread_id = "thread_#{SecureRandom.uuid.split('-').first}"
  run_id = SecureRandom.uuid

  messages = [
    build_multimodal_user_message,
    build_assistant_message
  ]

  tools = build_tools
  context = build_context

  run_agent_input = AgUiProtocol::Core::Types::RunAgentInput.new(
    thread_id: thread_id,
    run_id: run_id,
    state: {
      "conversation_stage" => "analyzing",
      "turn_count" => 1,
      "user_preferences" => { "detail_level" => "comprehensive" }
    },
    messages: messages,
    tools: tools,
    context: context,
    forwarded_props: {
      "client_version" => "1.0.0",
      "feature_flags" => { "multimodal" => true, "streaming" => true }
    }
  )

  puts "=== RunAgentInput Construction ==="
  puts
  puts "thread_id: #{run_agent_input.thread_id}"
  puts "run_id: #{run_agent_input.run_id}"
  puts
  puts "=== State ==="
  puts run_agent_input.state.to_json
  puts
  puts "=== Messages (#{run_agent_input.messages.size}) ==="
  run_agent_input.messages.each_with_index do |msg, idx|
    puts "Message #{idx + 1}:"
    puts "  id: #{msg.id}"
    puts "  role: #{msg.role}"
    if msg.content.is_a?(Array)
      puts "  content (multimodal):"
      msg.content.each do |c|
        puts "    - type: #{c.type}, #{c.respond_to?(:text) && c.text ? "text: #{c.text}" : "mime_type: #{c.mime_type}"}"
      end
    else
      puts "  content: #{msg.content}"
    end
    puts
  end
  puts
  puts "=== Tools (#{run_agent_input.tools.size}) ==="
  run_agent_input.tools.each do |tool|
    puts "  - #{tool.name}: #{tool.description}"
  end
  puts
  puts "=== Context (#{run_agent_input.context.size}) ==="
  run_agent_input.context.each do |ctx|
    puts "  - #{ctx.description}: #{ctx.value}"
  end
  puts
  puts "=== Forwarded Props ==="
  puts run_agent_input.forwarded_props.to_json
  puts
  puts "=== Full JSON Output ==="
  puts run_agent_input.to_json
end

main
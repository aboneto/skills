```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

# Plausible Ruby SDK pattern for constructing a multimodal RunAgentInput.
# If an actual SDK is available, replace the module below with:
#   require 'agent-runtime-sdk'

module AgentSdk
  module Types
    class TextInputContent
      attr_accessor :text

      def initialize(text:)
        @text = text
      end

      def to_h
        { type: 'text', text: @text }
      end
    end

    class BinaryInputContent
      attr_accessor :media_type, :data

      def initialize(media_type:, data:)
        @media_type = media_type
        @data = data
      end

      def to_h
        { type: 'binary', media_type: @media_type, data: @data }
      end
    end

    class UserMessage
      attr_accessor :role, :content

      def initialize(role: 'user', content: [])
        @role = role
        @content = content
      end

      def to_h
        { role: @role, content: @content.map(&:to_h) }
      end
    end

    class RunAgentInput
      attr_accessor :agent_id, :agent_alias_id, :session_id, :messages

      def initialize(agent_id:, agent_alias_id:, session_id:, messages:)
        @agent_id = agent_id
        @agent_alias_id = agent_alias_id
        @session_id = session_id
        @messages = messages
      end

      def to_h
        {
          agent_id: @agent_id,
          agent_alias_id: @agent_alias_id,
          session_id: @session_id,
          messages: @messages.map(&:to_h)
        }
      end
    end
  end
end

include AgentSdk::Types

def build_multimodal_input(image_path)
  # 1. Create text content
  text_content = TextInputContent.new(
    text: 'Please analyze the attached image and describe its contents.'
  )

  # 2. Create binary content from a local file
  binary_content = BinaryInputContent.new(
    media_type: 'image/png',
    data: File.binread(image_path)
  )

  # 3. Create a multimodal UserMessage containing both text and binary
  user_message = UserMessage.new(
    content: [text_content, binary_content]
  )

  # 4. Construct the complete RunAgentInput
  RunAgentInput.new(
    agent_id: 'your-agent-id',
    agent_alias_id: 'your-agent-alias-id',
    session_id: "session-#{Time.now.to_i}",
    messages: [user_message]
  )
end

if __FILE__ == $PROGRAM_NAME
  image_path = ARGV[0] || 'example.png'

  unless File.exist?(image_path)
    puts "Usage: #{$PROGRAM_NAME} <path-to-image>"
    exit 1
  end

  input = build_multimodal_input(image_path)

  puts "RunAgentInput constructed successfully:"
  puts "- Agent ID: #{input.agent_id}"
  puts "- Session ID: #{input.session_id}"
  puts "- Messages: #{input.messages.length}"
  puts "- Content items in first message: #{input.messages.first.content.length}"
end
```

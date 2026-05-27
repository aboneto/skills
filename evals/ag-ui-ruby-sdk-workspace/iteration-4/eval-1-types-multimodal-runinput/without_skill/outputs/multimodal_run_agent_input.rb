require "json"
require "base64"
require "securerandom"

module AgUiSdk
  class TextInputContent
    attr_reader :type, :text

    def initialize(text:)
      @type = "text"
      @text = text
    end

    def to_h
      { type: @type, text: @text }
    end
  end

  class BinaryInputContent
    attr_reader :type, :media_type, :data

    def initialize(media_type:, data:)
      @type = "binary"
      @media_type = media_type
      @data = data
    end

    def to_h
      { type: @type, mediaType => @media_type, data: @data }
    end
  end

  class UserMessage
    attr_reader :role, :content

    def initialize(content:)
      @role = "user"
      @content = content
    end

    def to_h
      { role: @role, content: @content.map(&:to_h) }
    end
  end

  class RunAgentInput
    attr_reader :messages, :agent_id, :session_id, :streaming

    def initialize(agent_id:, session_id: nil, streaming: true, messages: [])
      @agent_id = agent_id
      @session_id = session_id || SecureRandom.uuid
      @streaming = streaming
      @messages = messages
    end

    def add_message(message)
      @messages << message
    end

    def to_h
      {
        agentId: @agent_id,
        sessionId: @session_id,
        streaming: @streaming,
        messages: @messages.map(&:to_h)
      }.compact
    end

    def to_json(*args)
      to_h.to_json(*args)
    end
  end
end

def create_multimodal_message
  text_content = AgUiSdk::TextInputContent.new(
    text: "Analyze the attached image and provide insights."
  )

  image_data = Base64.strict_encode64(File.read("sample_image.png", binmode: true))
  binary_content = AgUiSdk::BinaryInputContent.new(
    media_type: "image/png",
    data: image_data
  )

  user_message = AgUiSdk::UserMessage.new(
    content: [text_content, binary_content]
  )

  user_message
end

def create_run_agent_input
  input = AgUiSdk::RunAgentInput.new(
    agent_id: "multimodal-agent-001",
    session_id: "session-12345",
    streaming: true
  )

  input.add_message(create_multimodal_message)

  input
end

if __FILE__ == $0
  run_input = create_run_agent_input

  puts "RunAgentInput JSON:"
  puts run_input.to_json

  output_dir = "evals/ag-ui-ruby-sdk-workspace/iteration-4/eval-1-types-multimodal-runinput/without_skill/outputs"
  File.write(File.join(output_dir, "run_agent_input.json"), run_input.to_json)

  puts "\nOutput saved to #{output_dir}/run_agent_input.json"
end
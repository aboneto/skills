require 'json'
require 'base64'

# Define standard models if they aren't already defined in the environment.
# This ensures the script is runnable and robust across different runtimes.
unless defined?(TextInputContent)
  class TextInputContent
    attr_accessor :text

    def initialize(text:)
      @text = text
    end

    def to_h
      { text: @text }
    end
  end
end

unless defined?(BinaryInputContent)
  class BinaryInputContent
    attr_accessor :data, :mime_type

    def initialize(data:, mime_type:)
      @data = data
      @mime_type = mime_type
    end

    def to_h
      {
        data: Base64.strict_encode64(@data),
        mime_type: @mime_type
      }
    end
  end
end

unless defined?(UserMessage)
  class UserMessage
    attr_accessor :content

    def initialize(content:)
      @content = content
    end

    def to_h
      { content: @content.map(&:to_h) }
    end
  end
end

unless defined?(RunAgentInput)
  class RunAgentInput
    attr_accessor :user_message, :agent_id, :session_id, :parameters

    def initialize(user_message:, agent_id:, session_id: nil, parameters: {})
      @user_message = user_message
      @agent_id = agent_id
      @session_id = session_id
      @parameters = parameters
    end

    def to_h
      {
        user_message: @user_message.to_h,
        agent_id: @agent_id,
        session_id: @session_id,
        parameters: @parameters
      }
    end
  end
end

# --- Object Construction ---

# 1. Create a text input content part
text_part = TextInputContent.new(
  text: "Please analyze the attached image and describe the architectural patterns visible."
)

# 2. Create a binary input content part (e.g. mock PNG image data)
mock_png_data = [137, 80, 78, 71, 13, 10, 26, 10].pack('C*') # PNG signature bytes
image_part = BinaryInputContent.new(
  data: mock_png_data,
  mime_type: "image/png"
)

# 3. Create the multimodal UserMessage
user_message = UserMessage.new(
  content: [text_part, image_part]
)

# 4. Construct the complete RunAgentInput object
run_agent_input = RunAgentInput.new(
  user_message: user_message,
  agent_id: "architecture-analyzer-agent-v1",
  session_id: "session-abc-12345",
  parameters: {
    temperature: 0.1,
    max_output_tokens: 1500
  }
)

# --- Demonstration and Output ---

puts "--- Constructed RunAgentInput Serialization ---"
puts JSON.pretty_generate(run_agent_input.to_h)

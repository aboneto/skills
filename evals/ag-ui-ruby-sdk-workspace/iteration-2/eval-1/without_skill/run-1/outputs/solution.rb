# frozen_string_literal: true

require "json"
require "base64"

# Content types for multimodal messages
class TextInputContent
  attr_reader :type, :text

  def initialize(text)
    @type = "text"
    @text = text
  end

  def to_h
    { type: type, text: text }
  end

  def to_json(*args)
    to_h.to_json(*args)
  end
end

class BinaryInputContent
  attr_reader :type, :data, :media_type

  def initialize(data, media_type:)
    @type = "binary"
    @data = data
    @media_type = media_type
  end

  def to_h
    { type: type, data: data, media_type: media_type }
  end

  def to_json(*args)
    to_h.to_json(*args)
  end

  # Convenience: load binary from file and base64-encode it
  def self.from_file(path, media_type:)
    raw = File.binread(path)
    encoded = Base64.strict_encode64(raw)
    new(encoded, media_type: media_type)
  end
end

class UserMessage
  attr_reader :role, :content

  def initialize(content)
    @role = "user"
    @content = content
  end

  def to_h
    { role: role, content: content.map(&:to_h) }
  end

  def to_json(*args)
    to_h.to_json(*args)
  end
end

class RunAgentInput
  attr_reader :agent_id, :messages, :max_tokens, :temperature

  def initialize(agent_id:, messages:, max_tokens: 1024, temperature: 0.7)
    @agent_id = agent_id
    @messages = messages
    @max_tokens = max_tokens
    @temperature = temperature
  end

  def to_h
    {
      agent_id: agent_id,
      messages: messages.map(&:to_h),
      max_tokens: max_tokens,
      temperature: temperature
    }
  end

  def to_json(*args)
    to_h.to_json(*args)
  end
end

# ---------------------------------------------------------------------------
# Example usage – multimodal message with text + image
# ---------------------------------------------------------------------------
if __FILE__ == $PROGRAM_NAME
  # Build text content
  text_part = TextInputContent.new("Describe what you see in this diagram.")

  # Build binary content (e.g. PNG image read from disk, base64-encoded)
  image_part = BinaryInputContent.from_file("diagram.png", media_type: "image/png")

  # Assemble the user message
  user_message = UserMessage.new([text_part, image_part])

  # Build the full agent input
  input = RunAgentInput.new(
    agent_id: "agent-v1",
    messages: [user_message],
    max_tokens: 2048,
    temperature: 0.5
  )

  puts JSON.pretty_generate(input.to_h)
end

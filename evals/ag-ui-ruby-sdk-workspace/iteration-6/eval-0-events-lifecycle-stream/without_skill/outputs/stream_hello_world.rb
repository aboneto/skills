require "json"

class RunLifecycleEncoder
  def initialize(stream)
    @stream = stream
  end

  def encode(type, data)
    event = { type: type, data: data, timestamp: Time.now.iso8601(3) }
    @stream.puts event.to_json
    @stream.flush
  end
end

stream = STDOUT
encoder = RunLifecycleEncoder.new(stream)

encoder.encode :run_start, { status: "starting" }
encoder.encode :message,   { content: "Hello, World!" }
encoder.encode :run_finish, { status: "completed" }

```ruby
require 'ag_ui_protocol'
require 'securerandom'
require 'stringio'

stream = StringIO.new
encoder = AgUiProtocol::Encoder::EventEncoder.new

thread_id = SecureRandom.uuid
run_id = SecureRandom.uuid
message_id = SecureRandom.uuid

# 1. START
stream.write(encoder.encode(
  AgUiProtocol::Core::Events::RunStartedEvent.new(thread_id: thread_id, run_id: run_id)
))
stream.flush if stream.respond_to?(:flush)

# 2. Stream text message: "Hello, World!"
stream.write(encoder.encode(
  AgUiProtocol::Core::Events::TextMessageStartEvent.new(message_id: message_id)
))
stream.flush if stream.respond_to?(:flush)

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::TextMessageContentEvent.new(
    message_id: message_id,
    delta: "Hello, World!"
  )
))
stream.flush if stream.respond_to?(:flush)

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::TextMessageEndEvent.new(message_id: message_id)
))
stream.flush if stream.respond_to?(:flush)

# 3. END (success)
stream.write(encoder.encode(
  AgUiProtocol::Core::Events::RunFinishedEvent.new(
    thread_id: thread_id,
    run_id: run_id,
    result: {}
  )
))
stream.flush if stream.respond_to?(:flush)

puts stream.string
```

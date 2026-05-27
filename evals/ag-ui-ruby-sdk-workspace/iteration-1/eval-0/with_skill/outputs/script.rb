# frozen_string_literal: true

require 'securerandom'
require 'ag_ui_protocol'

def run_lifecycle_stream(stream = $stdout)
  encoder = AgUiProtocol::Encoder::EventEncoder.new

  thread_id = SecureRandom.uuid
  run_id = SecureRandom.uuid
  message_id = SecureRandom.uuid

  run_started = AgUiProtocol::Core::Events::RunStartedEvent.new(
    thread_id: thread_id,
    run_id: run_id
  )
  stream.write(encoder.encode(run_started))
  stream.flush if stream.respond_to?(:flush)

  message_start = AgUiProtocol::Core::Events::TextMessageStartEvent.new(
    message_id: message_id
  )
  stream.write(encoder.encode(message_start))
  stream.flush if stream.respond_to?(:flush)

  message_content = AgUiProtocol::Core::Events::TextMessageContentEvent.new(
    message_id: message_id,
    delta: "Hello, World!"
  )
  stream.write(encoder.encode(message_content))
  stream.flush if stream.respond_to?(:flush)

  message_end = AgUiProtocol::Core::Events::TextMessageEndEvent.new(
    message_id: message_id
  )
  stream.write(encoder.encode(message_end))
  stream.flush if stream.respond_to?(:flush)

  run_finished = AgUiProtocol::Core::Events::RunFinishedEvent.new(
    thread_id: thread_id,
    run_id: run_id
  )
  stream.write(encoder.encode(run_finished))
  stream.flush if stream.respond_to?(:flush)
end

if __FILE__ == $0
  run_lifecycle_stream
end

#!/usr/bin/env ruby
require "ag-ui-protocol"
require "securerandom"

thread_id = SecureRandom.uuid
run_id = SecureRandom.uuid
message_id = SecureRandom.uuid

encoder = AgUiProtocol::Encoder::EventEncoder.new

stream = StringIO.new

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::RunStartedEvent.new(thread_id: thread_id, run_id: run_id)
))
stream.flush

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::TextMessageStartEvent.new(message_id: message_id)
))
stream.flush

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::TextMessageContentEvent.new(message_id: message_id, delta: "Hello, World!")
))
stream.flush

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::TextMessageEndEvent.new(message_id: message_id)
))
stream.flush

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::RunFinishedEvent.new(thread_id: thread_id, run_id: run_id)
))

puts stream.string
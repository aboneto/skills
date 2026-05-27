#!/usr/bin/env ruby
# frozen_string_literal: true

require "ag_ui_protocol"

encoder = AgUiProtocol::Encoder::EventEncoder.new
thread_id = SecureRandom.uuid
run_id = SecureRandom.uuid
message_id = SecureRandom.uuid

stream = $stdout

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::RunStartedEvent.new(thread_id: thread_id, run_id: run_id)
))
stream.flush

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::TextMessageStartEvent.new(message_id: message_id)
))
stream.flush

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::TextMessageContentEvent.new(
    message_id: message_id,
    delta: "Hello, World!"
  )
))
stream.flush

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::TextMessageEndEvent.new(message_id: message_id)
))
stream.flush

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::RunFinishedEvent.new(
    thread_id: thread_id,
    run_id: run_id,
    result: { status: "completed" }
  )
))
stream.flush

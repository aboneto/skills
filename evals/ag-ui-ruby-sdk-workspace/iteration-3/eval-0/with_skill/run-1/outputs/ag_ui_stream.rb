# frozen_string_literal: true

require "ag-ui-protocol"
require "stringio"

class AgUiStreamSimulator
  def initialize
    @encoder = AgUiProtocol::Encoder::EventEncoder.new
    @stream = StringIO.new
    @thread_id = "thread-1"
    @run_id = "run-1"
  end

  def write_event(event)
    @stream.write(@encoder.encode(event))
    @stream.flush if @stream.respond_to?(:flush)
  end

  def run
    write_event(AgUiProtocol::Core::Events::RunStartedEvent.new(
      thread_id: @thread_id,
      run_id: @run_id
    ))

    message_id = SecureRandom.uuid

    write_event(AgUiProtocol::Core::Events::TextMessageStartEvent.new(
      message_id: message_id
    ))

    write_event(AgUiProtocol::Core::Events::TextMessageContentEvent.new(
      message_id: message_id,
      delta: "Hello, World!"
    ))

    write_event(AgUiProtocol::Core::Events::TextMessageEndEvent.new(
      message_id: message_id
    ))

    write_event(AgUiProtocol::Core::Events::RunFinishedEvent.new(
      thread_id: @thread_id,
      run_id: @run_id
    ))

    @stream.string
  end
end

if __FILE__ == $PROGRAM_NAME
  simulator = AgUiStreamSimulator.new
  output = simulator.run

  puts "AG-UI Event Stream:"
  puts "-" * 40
  puts output
  puts "-" * 40
  puts "Success!"
end

#!/usr/bin/env ruby

require 'ag-ui-protocol'
require 'json'

module AG
  module UI
    class StreamClient
      def initialize(run_id:, message_id:)
        @run_id = run_id
        @message_id = message_id
      end

      def send_event(event)
        puts event.to_json
      end

      def start_run
        send_event(Protocol::Events::RunStartedEvent.new(run_id: @run_id))
      end

      def send_text_message(content)
        send_event(Protocol::Events::TextMessageStartEvent.new(
          run_id: @run_id,
          message_id: @message_id,
          role: "assistant"
        ))

        send_event(Protocol::Events::TextMessageContentEvent.new(
          run_id: @run_id,
          message_id: @message_id,
          content: content
        ))

        send_event(Protocol::Events::TextMessageEndEvent.new(
          run_id: @run_id,
          message_id: @message_id
        ))
      end

      def finish_run
        send_event(Protocol::Events::RunFinishedEvent.new(run_id: @run_id))
      end
    end
  end
end

run_id = "run-#{SecureRandom.hex(8)}"
message_id = "msg-#{SecureRandom.hex(8)}"

client = AG::UI::StreamClient.new(run_id: run_id, message_id: message_id)
client.start_run
client.send_text_message("Hello, World!")
client.finish_run

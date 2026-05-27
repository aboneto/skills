#!/usr/bin/env ruby

require 'json'
require 'securerandom'

class AgUiClient
  def initialize(base_url)
    @base_url = base_url
  end

  def start_run(run_id, thread_id = nil)
    payload = {
      type: "start_run",
      runId: run_id,
      threadId: thread_id
    }.compact

    emit_event(payload)
  end

  def stream_text(run_id, content, message_id = nil)
    payload = {
      type: "text_message",
      runId: run_id,
      messageId: message_id || SecureRandom.uuid,
      content: content,
      stream: true
    }

    emit_event(payload)
  end

  def finish_run(run_id, status = "complete")
    payload = {
      type: "finish_run",
      runId: run_id,
      status: status
    }

    emit_event(payload)
  end

  private

  def emit_event(payload)
    puts "[AG-UI] Emitting event: #{payload[:type]}"
    puts JSON.generate(payload)
    payload
  end
end

run_id = SecureRandom.uuid
client = AgUiClient.new("http://localhost:3000")

puts "Starting AG-UI run..."
client.start_run(run_id)
sleep(0.1)

puts "\nStreaming text message..."
client.stream_text(run_id, "Hello, World!")
sleep(0.1)

puts "\nFinishing run..."
client.finish_run(run_id, "complete")

puts "\n[AG-UI] Run completed successfully!"

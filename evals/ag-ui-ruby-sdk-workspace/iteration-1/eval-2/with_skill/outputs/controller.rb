require "securerandom"
require "ag_ui_protocol"

class StreamingController < ApplicationController
  # Include ActionController::Live to support Server-Sent Events (SSE)
  include ActionController::Live

  # Pattern 1: Client streaming with rack.hijack using a helper `with_stream`
  def stream_hijack
    encoder = AgUiProtocol::Encoder::EventEncoder.new(accept: request.headers["Accept"])
    thread_id = params[:thread_id] || SecureRandom.uuid
    run_id = params[:run_id] || SecureRandom.uuid

    with_stream(encoder.content_type) do |stream|
      begin
        # 1. Start the run
        stream.write(encoder.encode(
          AgUiProtocol::Core::Events::RunStartedEvent.new(
            thread_id: thread_id,
            run_id: run_id
          )
        ))
        stream.flush if stream.respond_to?(:flush)

        # 2. Stream a text message sequence
        message_id = SecureRandom.uuid
        stream.write(encoder.encode(
          AgUiProtocol::Core::Events::TextMessageStartEvent.new(message_id: message_id)
        ))
        stream.flush if stream.respond_to?(:flush)

        stream.write(encoder.encode(
          AgUiProtocol::Core::Events::TextMessageContentEvent.new(
            message_id: message_id,
            delta: "Streaming via hijacked connection using rack.hijack."
          )
        ))
        stream.flush if stream.respond_to?(:flush)

        stream.write(encoder.encode(
          AgUiProtocol::Core::Events::TextMessageEndEvent.new(message_id: message_id)
        ))
        stream.flush if stream.respond_to?(:flush)

        # 3. Finish the run
        stream.write(encoder.encode(
          AgUiProtocol::Core::Events::RunFinishedEvent.new(
            thread_id: thread_id,
            run_id: run_id,
            result: { "status" => "ok" }
          )
        ))
        stream.flush if stream.respond_to?(:flush)

      rescue IOError => e
        Rails.logger.warn("AG-UI client disconnected during hijack stream: #{e.message}")
      rescue StandardError => e
        # Emit error event before re-raising
        stream.write(encoder.encode(
          AgUiProtocol::Core::Events::RunErrorEvent.new(
            message: e.message,
            code: e.class.name
          )
        ))
        stream.flush if stream.respond_to?(:flush)
        raise
      ensure
        # Clean up / close the stream in ensure blocks
        stream.close if stream.respond_to?(:close)
      end
    end
  end

  # Pattern 2: Server-Sent Events (SSE) streaming with ActionController::Live
  def stream_live
    # Set correct headers for Server-Sent Events (SSE)
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    encoder = AgUiProtocol::Encoder::EventEncoder.new
    thread_id = params[:thread_id] || SecureRandom.uuid
    run_id = params[:run_id] || SecureRandom.uuid
    stream = response.stream

    begin
      # 1. Start the run
      stream.write(encoder.encode(
        AgUiProtocol::Core::Events::RunStartedEvent.new(
          thread_id: thread_id,
          run_id: run_id
        )
      ))

      # 2. Stream a text message sequence
      message_id = SecureRandom.uuid
      stream.write(encoder.encode(
        AgUiProtocol::Core::Events::TextMessageStartEvent.new(message_id: message_id)
      ))

      stream.write(encoder.encode(
        AgUiProtocol::Core::Events::TextMessageContentEvent.new(
          message_id: message_id,
          delta: "Streaming via ActionController::Live response stream."
        )
      ))

      stream.write(encoder.encode(
        AgUiProtocol::Core::Events::TextMessageEndEvent.new(message_id: message_id)
      ))

      # 3. Finish the run
      stream.write(encoder.encode(
        AgUiProtocol::Core::Events::RunFinishedEvent.new(
          thread_id: thread_id,
          run_id: run_id,
          result: { "status" => "ok" }
        )
      ))

    rescue IOError => e
      # Handle client disconnect gracefully
      Rails.logger.warn("AG-UI client disconnected during Live stream: #{e.message}")
    rescue StandardError => e
      # Emit error event before re-raising
      stream.write(encoder.encode(
        AgUiProtocol::Core::Events::RunErrorEvent.new(
          message: e.message,
          code: e.class.name
        )
      ))
      raise
    ensure
      # Clean up / close the stream in ensure blocks
      stream.close if stream.respond_to?(:close)
    end
  end

  private

  # Helper method to handle rack hijacking with with_stream pattern
  def with_stream(content_type)
    response.headers["Content-Type"] = content_type
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    response.headers["rack.hijack"] = proc do |stream|
      Thread.new do
        begin
          yield stream
        rescue IOError => e
          Rails.logger.warn("AG-UI client disconnected in hijack thread: #{e.message}")
        rescue => e
          Rails.logger.error("AG-UI stream error in hijack thread: #{e.message}")
        ensure
          stream.close if stream.respond_to?(:close)
        end
      end
    end
  end
end

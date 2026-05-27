require "securerandom"
require "ag_ui_protocol"

class AgUiStreamingController < ActionController::API
  def with_stream_endpoint
    encoder = AgUiProtocol::Encoder::EventEncoder.new(accept: request.headers["Accept"])
    thread_id = params[:thread_id] || SecureRandom.uuid
    run_id = params[:run_id] || SecureRandom.uuid

    with_stream(encoder.content_type) do |stream|
      begin
        stream.write(encoder.encode(
          AgUiProtocol::Core::Events::RunStartedEvent.new(
            thread_id: thread_id,
            run_id: run_id
          )
        ))
        stream.flush if stream.respond_to?(:flush)

        message_id = SecureRandom.uuid
        stream.write(encoder.encode(
          AgUiProtocol::Core::Events::TextMessageStartEvent.new(message_id: message_id)
        ))
        stream.flush if stream.respond_to?(:flush)

        content = params[:content] || "Hello from with_stream pattern!"
        content.each_char do |char|
          stream.write(encoder.encode(
            AgUiProtocol::Core::Events::TextMessageContentEvent.new(
              message_id: message_id,
              delta: char
            )
          ))
          stream.flush if stream.respond_to?(:flush)
          sleep 0.01
        end

        stream.write(encoder.encode(
          AgUiProtocol::Core::Events::TextMessageEndEvent.new(message_id: message_id)
        ))
        stream.flush if stream.respond_to?(:flush)

        stream.write(encoder.encode(
          AgUiProtocol::Core::Events::RunFinishedEvent.new(
            thread_id: thread_id,
            run_id: run_id,
            result: { "status" => "ok" }
          )
        ))
        stream.flush if stream.respond_to?(:flush)

      rescue StandardError => e
        encoder ||= AgUiProtocol::Encoder::EventEncoder.new(accept: request.headers["Accept"])
        stream.write(encoder.encode(
          AgUiProtocol::Core::Events::RunErrorEvent.new(message: e.message, code: e.class.name)
        ))
        stream.flush if stream.respond_to?(:flush)
        raise
      end
    end

    head :ok
  end

  def live_stream_endpoint
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    encoder = AgUiProtocol::Encoder::EventEncoder.new
    thread_id = params[:thread_id] || SecureRandom.uuid
    run_id = params[:run_id] || SecureRandom.uuid

    begin
      response.stream.write(encoder.encode(
        AgUiProtocol::Core::Events::RunStartedEvent.new(
          thread_id: thread_id,
          run_id: run_id
        )
      ))
      response.stream.flush if response.stream.respond_to?(:flush)

      message_id = SecureRandom.uuid
      response.stream.write(encoder.encode(
        AgUiProtocol::Core::Events::TextMessageStartEvent.new(message_id: message_id)
      ))
      response.stream.flush if response.stream.respond_to?(:flush)

      content = params[:content] || "Hello from ActionController::Live pattern!"
      content.each_char do |char|
        response.stream.write(encoder.encode(
          AgUiProtocol::Core::Events::TextMessageContentEvent.new(
            message_id: message_id,
            delta: char
          )
        ))
        response.stream.flush if response.stream.respond_to?(:flush)
        sleep 0.01
      end

      response.stream.write(encoder.encode(
        AgUiProtocol::Core::Events::TextMessageEndEvent.new(message_id: message_id)
      ))
      response.stream.flush if response.stream.respond_to?(:flush)

      response.stream.write(encoder.encode(
        AgUiProtocol::Core::Events::RunFinishedEvent.new(
          thread_id: thread_id,
          run_id: run_id,
          result: { "status" => "ok" }
        )
      ))
      response.stream.flush if response.stream.respond_to?(:flush)

    rescue IOError => e
      Rails.logger.warn("AG-UI client disconnected: #{e.message}")

    rescue StandardError => e
      Rails.logger.error("AG-UI stream error: #{e.message}")
      begin
        encoder ||= AgUiProtocol::Encoder::EventEncoder.new
        response.stream.write(encoder.encode(
          AgUiProtocol::Core::Events::RunErrorEvent.new(message: e.message, code: e.class.name)
        ))
        response.stream.flush if response.stream.respond_to?(:flush)
      rescue IOError
        Rails.logger.warn("Could not send error event after disconnect")
      end

    ensure
      response.stream.close if response.stream.respond_to?(:close)
    end

    head :ok
  end

  private

  def with_stream(content_type)
    response.headers["Content-Type"] = content_type
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    response.headers["rack.hijack"] = proc do |stream|
      Thread.new do
        begin
          yield stream
        rescue IOError => e
          Rails.logger.warn("AG-UI client disconnected: #{e.message}")
        rescue => e
          Rails.logger.error("AG-UI stream error: #{e.message}")
          stream.flush if stream.respond_to?(:flush)
        ensure
          stream.close if stream.respond_to?(:close)
        end
      end
    end
  end
end
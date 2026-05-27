require "securerandom"
require "ag_ui_protocol"

class AgUiStreamingController < ActionController::API
  def with_stream_action
    encoder = AgUiProtocol::Encoder::EventEncoder.new(accept: request.headers["Accept"])
    thread_id = params[:thread_id] || SecureRandom.uuid
    run_id = params[:run_id] || SecureRandom.uuid

    with_stream(encoder.content_type) do |stream|
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

      sleep(0.5)

      stream.write(encoder.encode(
        AgUiProtocol::Core::Events::TextMessageContentEvent.new(
          message_id: message_id,
          delta: "Hello from with_stream!"
        )
      ))
      stream.flush if stream.respond_to?(:flush)

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

    ensure
      stream.close if stream.respond_to?(:close)
    end

    head :ok
  end

  def live_action
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    encoder = AgUiProtocol::Encoder::EventEncoder.new
    thread_id = params[:thread_id] || SecureRandom.uuid
    run_id = params[:run_id] || SecureRandom.uuid

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

      sleep(0.5)

      stream.write(encoder.encode(
        AgUiProtocol::Core::Events::TextMessageContentEvent.new(
          message_id: message_id,
          delta: "Hello from ActionController::Live!"
        )
      ))
      stream.flush if stream.respond_to?(:flush)

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

    rescue IOError => e
      Rails.logger.warn("AG-UI client disconnected: #{e.message}")

    ensure
      stream.close if stream.respond_to?(:close)
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

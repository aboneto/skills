```ruby
# app/controllers/ag_ui_controller.rb
class AgUiController < ActionController::API
  # =============================================================================
  # ActionController::Live pattern — works with any Rails version
  # =============================================================================
  include ActionController::Live

  def run_with_live
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    encoder = AgUiProtocol::Encoder::EventEncoder.new
    thread_id = params[:thread_id] || SecureRandom.uuid
    run_id = params[:run_id] || SecureRandom.uuid

    begin
      # Emit RunStartedEvent
      response.stream.write(encoder.encode(
        AgUiProtocol::Core::Events::RunStartedEvent.new(thread_id: thread_id, run_id: run_id)
      ))

      # Simulate streaming work — replace with your real event loop
      5.times do |i|
        response.stream.write(encoder.encode(
          AgUiProtocol::Core::Events::TextMessageEvent.new(
            thread_id: thread_id,
            run_id: run_id,
            role: "assistant",
            text: "Chunk #{i + 1}\n"
          )
        ))
        sleep 0.5
      end

      # Emit RunFinishedEvent
      response.stream.write(encoder.encode(
        AgUiProtocol::Core::Events::RunFinishedEvent.new(thread_id: thread_id, run_id: run_id)
      ))
    rescue IOError => e
      Rails.logger.warn("AG-UI client disconnected (Live): #{e.message}")
    rescue => e
      Rails.logger.error("AG-UI stream error (Live): #{e.message}")
    ensure
      response.stream.close if response.stream.respond_to?(:close)
    end
  end

  # =============================================================================
  # with_stream pattern — requires Rails 7.1+ (uses rack.hijack)
  # =============================================================================

  def run_with_hijack
    encoder = AgUiProtocol::Encoder::EventEncoder.new(accept: request.headers["Accept"])
    thread_id = params[:thread_id] || SecureRandom.uuid
    run_id = params[:run_id] || SecureRandom.uuid

    with_stream(encoder.content_type) do |stream|
      # Emit RunStartedEvent
      stream.write(encoder.encode(
        AgUiProtocol::Core::Events::RunStartedEvent.new(thread_id: thread_id, run_id: run_id)
      ))

      # Simulate streaming work — replace with your real event loop
      5.times do |i|
        stream.write(encoder.encode(
          AgUiProtocol::Core::Events::TextMessageEvent.new(
            thread_id: thread_id,
            run_id: run_id,
            role: "assistant",
            text: "Chunk #{i + 1}\n"
          )
        ))
        sleep 0.5
      end

      # Emit RunFinishedEvent
      stream.write(encoder.encode(
        AgUiProtocol::Core::Events::RunFinishedEvent.new(thread_id: thread_id, run_id: run_id)
      ))
    end
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
          Rails.logger.warn("AG-UI client disconnected (hijack): #{e.message}")
        rescue => e
          Rails.logger.error("AG-UI stream error (hijack): #{e.message}")
          stream.flush if stream.respond_to?(:flush)
        ensure
          stream.close if stream.respond_to?(:close)
        end
      end
    end
  end
end
```

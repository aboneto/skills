class StreamController < ApplicationController
  include ActionController::Live

  # Pattern 1: ActionController::Live with text/event-stream
  def events
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no'

    sse = AgUi::Stream::SSE.new(response.stream)

    begin
      loop do
        sse.write(event: 'message', data: { time: Time.current.iso8601 })
        sleep 1
      end
    rescue IOError, ActionController::Live::ClientDisconnected
      # Client disconnected
    ensure
      sse.close
      response.stream.close
    end
  end

  # Pattern 2: with_stream using rack.hijack for bidirectional streaming
  def bidirectional
    with_stream do |stream|
      stream.on_data do |chunk|
        handle_client_data(chunk)
      end

      begin
        loop do
          stream.write({ type: 'tick', at: Time.current.iso8601 })
          sleep 2
        end
      rescue IOError
        # Client disconnected
      ensure
        stream.close
      end
    end
  end

  private

  def handle_client_data(data)
    Rails.logger.info("Received from client: #{data}")
  end
end

```ruby
class StreamsController < ApplicationController
  include ActionController::Live

  # Pattern 1: with_stream using rack.hijack for client streaming
  def client_stream
    unless request.env['rack.hijack']
      head :not_implemented
      return
    end

    request.env['rack.hijack'].call
    io = request.env['rack.hijack_io']
    stream = nil

    begin
      stream = Agui::Stream.with_stream(io)
      stream.write("Connected to client stream\n")
      stream.flush

      loop do
        data = io.readpartial(4096)
        response = process_client_data(data)
        stream.write(response)
        stream.flush
      end
    rescue EOFError
      logger.info "Client stream closed by peer"
    rescue StandardError => e
      logger.error "Client stream error: #{e.message}"
    ensure
      stream&.close rescue nil
      io&.close rescue nil
    end
  end

  # Pattern 2: ActionController::Live with SSE and client disconnect handling
  def server_stream
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no'

    stream = nil

    begin
      stream = Agui::Stream.with_stream(response.stream)

      loop do
        payload = {
          time: Time.now.iso8601,
          message: 'server event'
        }.to_json

        stream.write("data: #{payload}\n\n")
        stream.flush
        sleep 1
      end
    rescue IOError
      logger.info "Client disconnected from server_stream"
    rescue StandardError => e
      logger.error "Server stream error: #{e.message}"
    ensure
      stream&.close rescue nil
      response.stream.close rescue nil
    end
  end

  private

  def process_client_data(data)
    { received: data.strip, processed_at: Time.now.iso8601 }.to_json
  end
end
```

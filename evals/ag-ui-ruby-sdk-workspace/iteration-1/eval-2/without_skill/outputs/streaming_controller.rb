class StreamingController < ApplicationController
  include ActionController::Live

  # Pattern 1: Client streaming with rack.hijack using a helper `with_stream`
  def client_stream
    with_stream do |stream|
      # Read chunked data sent by the client
      while (chunk = stream.read(1024))
        # Process the incoming client chunk
        Rails.logger.info("Received client stream chunk: #{chunk.bytesize} bytes")
      end
      # Write a standard HTTP response back to the hijacked socket
      stream.write("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 2\r\n\r\nOK")
    end
  end

  # Pattern 2: Server-Sent Events (SSE) streaming with ActionController::Live
  def server_stream
    # Set correct headers for Server-Sent Events (SSE)
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Last-Modified'] = Time.now.httpdate
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no' # Disable Nginx response buffering

    begin
      10.times do |i|
        # Write event stream formatted output
        response.stream.write("event: progress\n")
        response.stream.write("data: {\"step\": #{i}, \"timestamp\": \"#{Time.now.iso8601}\"}\n\n")
        sleep 1
      end
    rescue IOError => e
      # Handle client disconnect gracefully
      Rails.logger.info("Client disconnected from server stream: #{e.message}")
    ensure
      # Clean up and close the stream to release the Puma/thin thread/connection
      response.stream.close
    end
  end

  private

  # Helper method to handle rack hijacking
  def with_stream
    unless request.env['rack.hijack']
      render plain: "Rack hijacking not supported by the application server.", status: :not_implemented
      return
    end

    # Hijack the connection
    request.env['rack.hijack'].call
    # Get the raw I/O object
    stream = request.env['rack.hijack_io']

    begin
      yield stream
    rescue IOError => e
      Rails.logger.warn("IOError during client hijack stream processing: #{e.message}")
    ensure
      # Always ensure the stream is closed after yielding
      stream.close if stream && !stream.closed?
    end
  end
end

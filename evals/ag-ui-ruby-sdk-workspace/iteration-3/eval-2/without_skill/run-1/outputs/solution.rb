class AgUiStreamController < ApplicationController
  def stream_hijack
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no'
    response.headers['Transfer-Encoding'] = 'chunked'

    with_stream do |stream|
      stream.on :message do |event|
        handle_client_message(stream, event.data)
      end

      stream.on :function_call do |event|
        result = execute_function(event.data)
        stream.emit(type: 'function_call_result', data: result)
      end

      stream.emit(type: 'connection', data: { status: 'established', session_id: SecureRandom.uuid })

      stream.on_close do
        logger.info 'Client disconnected from hijacked stream'
      end
    end
  rescue IOError
  rescue => e
    logger.error "Stream error: #{e.message}"
  end

  def stream_live
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no'

    begin
      stream.emit(type: 'connection', data: { status: 'established', session_id: SecureRandom.uuid })

      loop do
        message = receive_message_from_queue
        stream.emit(type: 'message', data: message)
      end
    rescue IOError, ActionController::Live::ClientDisconnected
      logger.info 'Client disconnected from live stream'
    rescue => e
      stream.emit(type: 'error', data: { message: e.message })
    ensure
      stream.close if stream
    end
  end

  private

  def stream
    @stream ||= ResponseStream.new(response)
  end

  def handle_client_message(stream, data)
    stream.emit(type: 'ack', data: { received: data[:event_id] })
  end

  def execute_function(data)
    { function: data[:name], args: data[:arguments], result: 'processed' }
  end

  def receive_message_from_queue
    sleep 0.1
    { timestamp: Time.current.to_i }
  end

  class ResponseStream
    include Enumerable

    def initialize(response)
      @response = response
      @closed = false
    end

    def emit(type:, data:)
      return if @closed
      @response.stream.write "event: #{type}\n"
      @response.stream.write "data: #{data.to_json}\n\n"
    end

    def close
      return if @closed
      @closed = true
      @response.stream.close
    end

    def closed?
      @closed
    end
  end
end

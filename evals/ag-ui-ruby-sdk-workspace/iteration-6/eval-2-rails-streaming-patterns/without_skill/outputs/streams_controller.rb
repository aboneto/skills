class StreamsController < ApplicationController
  include ActionController::Live

  def live
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no'

    begin
      loop do
        response.stream.write "data: #{Time.now}\n\n"
        sleep 1
      end
    rescue IOError
      # Client disconnected
    ensure
      response.stream.close
    end
  end

  def hijack
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no'

    if request.env['rack.hijack']
      request.env['rack.hijack'].call
      io = request.env['rack.hijack_io']

      begin
        loop do
          io.write "data: #{Time.now}\n\n"
          io.flush
          sleep 1
        end
      rescue IOError
        # Client disconnected
      ensure
        io.close if io && !io.closed?
      end
    else
      head :not_found
    end
  end
end

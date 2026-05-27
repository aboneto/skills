# frozen_string_literal: true

require "action_controller"
require "ag_ui"

class StreamingController < ActionController::Base
  include ActionController::Live

  PROTOCOL_VERSION = "1.0"

  def client_streaming
    response.headers["Content-Type"] = "application/octet-stream"
    response.headers["X-Accel-Buffering"] = "no"
    response.headers["Cache-Control"] = "no-cache"

    begin
      stream = response.stream

      header_event = AGUI::Protocol::Event.new(
        event_id: "header-1",
        event_type: "application/agent-ui",
        protocol_version: PROTOCOL_VERSION,
        payload: { type: "header", status: 200 }.to_json
      )
      stream.write(header_event.to_binary)

      heartbeat_interval = Thread.new do
        loop do
          sleep 15
          break if stream.closed?
          begin
            heartbeat = AGUI::Protocol::Event.new(
              event_id: "heartbeat-#{Time.now.to_i}",
              event_type: "application/agent-ui",
              protocol_version: PROTOCOL_VERSION,
              payload: { type: "heartbeat" }.to_json
            )
            stream.write(heartbeat.to_binary)
          rescue IOError
            break
          end
        end
      end

      request_body.each do |chunk|
        break if stream.closed?
        event = AGUI::Protocol::Event.new(
          event_id: "chunk-#{Time.now.to_i}",
          event_type: "application/agent-ui",
          protocol_version: PROTOCOL_VERSION,
          payload: { type: "chunk", data: chunk }.to_json
        )
        stream.write(event.to_binary)
      end

      completion_event = AGUI::Protocol::Event.new(
        event_id: "completion-#{Time.now.to_i}",
        event_type: "application/agent-ui",
        protocol_version: PROTOCOL_VERSION,
        payload: { type: "completion" }.to_json
      )
      stream.write(completion_event.to_binary)
    rescue IOError, Errno::EPIPE
      Rails.logger.info "Client disconnected during streaming"
    ensure
      heartbeat_interval&.kill
      response.stream.close rescue nil
    end

    response.stream.close rescue nil
    head :ok
  end

  def event_stream
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["X-Accel-Buffering"] = "no"
    response.headers["Cache-Control"] = "no-cache"

    begin
      10.times do |i|
        break if response.stream.closed?
        response.stream.write "data: {\"type\":\"progress\",\"step\":#{i}}\n\n"
        response.stream.write "data: {\"type\":\"message\",\"content\":\"Step #{i} completed\"}\n\n"
        sleep 1
      end
      response.stream.write "data: {\"type\":\"done\"}\n\n"
    rescue IOError
      Rails.logger.info "Client disconnected from event stream"
    ensure
      response.stream.close rescue nil
    end

    head :ok
  rescue IOError
    Rails.logger.info "SSE stream closed"
  ensure
    response.stream.close rescue nil
  end

  private

  def request_body
    return enum_for(:request_body) unless request.body

    if request.body.respond_to?(:each_chunk)
      request.body.each_chunk
    elsif request.body.respond_to?(:each)
      request.body.each
    else
      [request.body.read]
    end
  end
end
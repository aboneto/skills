#!/usr/bin/env ruby
# frozen_string_literal: true

require 'ag_ui'

def run_hello_world
  # Start the run
  puts "Starting AG-UI Run..."
  run = AgUi.start_run

  # Stream the 'Hello, World!' message
  puts "Streaming message..."
  run.stream_text("Hello, World!")

  # Finish the run successfully
  puts "Finishing run..."
  run.finish

  puts "Run completed successfully."
rescue => e
  # Fallback to alternative block/class-based structure of the SDK if needed
  begin
    AgUi::Run.start do |r|
      r.stream_text("Hello, World!")
    end
  rescue => err
    raise "Failed to execute AG-UI run: #{e.message} (Fallback failed: #{err.message})"
  end
end

run_hello_world if __FILE__ == $0

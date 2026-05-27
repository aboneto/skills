#!/usr/bin/env ruby
# frozen_string_literal: true

def emit_reasoning_start
  puts 'data: {"type":"reasoning","object":{"type":"reasoning.start"}}'
  puts ''
  $stdout.flush
end

def emit_reasoning_message(chunks)
  chunks.each do |chunk|
    puts "data: {\"type\":\"reasoning\",\"object\":{\"type\":\"reasoning.message.start\"}}"
    puts ''
    puts "data: {\"type\":\"reasoning\",\"object\":{\"type\":\"reasoning.message.content\",\"content\":\"#{chunk}\"}}"
    puts ''
    $stdout.flush
    sleep(0.1)
  end
  puts 'data: {"type":"reasoning","object":{"type":"reasoning.message.end"}}'
  puts ''
  $stdout.flush
end

def emit_reasoning_end
  puts 'data: {"type":"reasoning","object":{"type":"reasoning.end"}}'
  puts ''
  $stdout.flush
end

emit_reasoning_start

emit_reasoning_message([
  "The user is asking for a Ruby script",
  "that emits a reasoning block",
  "with streaming reasoning messages."
])

emit_reasoning_end

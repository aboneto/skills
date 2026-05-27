---
name: ag-ui-ruby-sdk
description: "Complete agent skill for the AG-UI Ruby SDK (ag-ui-protocol gem). Use when working with Ruby/Rails applications that implement the Agent-User Interaction Protocol — streaming text responses, tool calls, lifecycle events, state management, ActionController::Live, with_stream pattern, EventEncoder, RunAgentInput, or any event type from the SDK. Triggers on 'AG-UI Ruby', 'ag-ui-protocol gem', 'Ruby SDK tool calls', 'Rails streaming endpoint', 'ActionController::Live AG-UI', 'with_stream pattern Ruby', or when looking at /ag-ui/sdks/community/ruby."
license: MIT
metadata:
  author: aboneto
  version: "1.0.0"
---

# ag-ui-ruby-sdk

Quick reference for using the AG-UI Ruby SDK (`ag-ui-protocol` gem). The body has high-frequency patterns. For deeper dives, read the matching file under `references/`.

## When to reach for which reference

| If the user needs this... | Read this file |
|---|---|
| Event types, lifecycle sequences, streaming patterns, chunk events | `references/events.md` |
| Message types (User, Assistant, Tool...), multimodal content, RunAgentInput, Sorbet validation | `references/types.md` |
| EventEncoder API, SSE format, content negotiation | `references/encoder.md` |
| Rails streaming patterns (with_stream or ActionController::Live), headers, error handling, client disconnect | `references/rails.md` |

---

## The 20% that covers 80% of use cases

### Stream a text message

```ruby
encoder = AgUiProtocol::Encoder::EventEncoder.new
message_id = SecureRandom.uuid

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::TextMessageStartEvent.new(message_id: message_id)
))
stream.flush if stream.respond_to?(:flush)

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::TextMessageContentEvent.new(
    message_id: message_id,
    delta: "Hello"
  )
))
stream.flush if stream.respond_to?(:flush)

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::TextMessageEndEvent.new(message_id: message_id)
))
```

### The mandatory event order

Every run looks like this:

```ruby
# 1. START
stream.write(encoder.encode(RunStartedEvent.new(thread_id: t, run_id: r)))

# 2. ... messages, tool calls, thinking, state ...

# 3. END (success or failure)
stream.write(encoder.encode(RunFinishedEvent.new(thread_id: t, run_id: r, result: {...})))
# OR
stream.write(encoder.encode(RunErrorEvent.new(message: e.message)))
```

**Order matters.** RunStarted must be first. RunFinished or RunError must be last.

### Emit an error

```ruby
rescue StandardError => e
  stream.write(encoder.encode(
    AgUiProtocol::Core::Events::RunErrorEvent.new(message: e.message, code: e.class.name)
  ))
  raise
```

### Rails streaming (with_stream, Rails 7.1+)

```ruby
class AgUiController < ActionController::API
  def run
    encoder = AgUiProtocol::Encoder::EventEncoder.new(accept: request.headers["Accept"])

    with_stream(encoder.content_type) do |stream|
      # emit events here
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
```

### Rails streaming (ActionController::Live, any Rails)

```ruby
class AgUiController < ActionController::API
  include ActionController::Live  # REQUIRED — this unlocks response.stream

  def run
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    encoder = AgUiProtocol::Encoder::EventEncoder.new

    begin
      # emit events here — use response.stream, NOT a local variable
      response.stream.write(encoder.encode(
        AgUiProtocol::Core::Events::RunStartedEvent.new(thread_id: t, run_id: r)
      ))
    rescue IOError
      Rails.logger.warn("Client disconnected")
    ensure
      response.stream.close if response.stream.respond_to?(:close)
    end
  end
end
```

### Create a UserMessage

```ruby
# Plain text
msg = AgUiProtocol::Core::Types::UserMessage.new(id: "1", content: "Hello!")

# Multimodal (text + image)
msg = AgUiProtocol::Core::Types::UserMessage.new(
  id: "2",
  content: [
    AgUiProtocol::Core::Types::TextInputContent.new(text: "Describe this"),
    AgUiProtocol::Core::Types::BinaryInputContent.new(
      mime_type: "image/png",
      url: "https://example.com/cat.png"
    )
  ]
)
```

---

## Common mistakes

1. **Missing message_id match** — TextMessageStart, Content, and End must share the same `message_id`.
2. **Forgetting to flush** — Add `stream.flush if stream.respond_to?(:flush)` after each write.
3. **Wrong event order** — RunStarted FIRST, RunFinished/RunError LAST.
4. **Not handling client disconnect** — `IOError` rescue is required.
5. **Invalid BinaryInputContent** — Must provide at least one of `id`, `url`, or `data`.
6. **Wrong messages type in RunAgentInput** — Sorbet validates that `messages` is Array of BaseMessage.
7. **Missing ActionController::Live include** — When using the `ActionController::Live` pattern, you MUST include `ActionController::Live` in the class declaration AND use `response.stream` (not a local variable named `stream`).

---

## Key SDK constants

```ruby
# Event types
AgUiProtocol::Core::Events::EventType::RUN_STARTED
AgUiProtocol::Core::Events::EventType::TEXT_MESSAGE_START
AgUiProtocol::Core::Events::EventType::TOOL_CALL_START
# ... all 27 types in references/events.md

# Roles
AgUiProtocol::Core::Types::Role
# => ["developer", "system", "assistant", "user", "tool", "activity"]
```

---

## When to use which event pattern

**Text streaming:** Use Start/Content/End for granular control. Use Chunk for simplicity (some clients auto-expand).

**Tool calls:** Same — Start/Args/End or Chunk.

**State sync:** Use StateSnapshotEvent (full) or StateDeltaEvent (JSON Patch incremental).

**Thinking:** Use ThinkingStart/End for wrapper, ThinkingTextMessageStart/Content/End for text.

See `references/events.md` for all 27 event types with full details.

## How to use this skill

1. Check the table at the top — open the matching `references/*.md` for depth.
2. Prefer giving working code snippets over abstract explanation.
3. Always verify event order: RunStarted → ... → RunFinished/RunError.
4. When in doubt about a specific event type or property, read the relevant reference file.

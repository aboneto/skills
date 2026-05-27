# Rails Integration

Two patterns exist for streaming AG-UI events in Rails. Choose based on your Rails version.

## Which Pattern to Use

| Pattern | Rails Version | Mechanism | Thread Safety |
|---------|---------------|------------|---------------|
| `with_stream` | 7.1+ | `rack.hijack` | Spawns a thread per request |
| `ActionController::Live` | Any | `response.stream` | Single-threaded per request |

**Prefer `with_stream`** if you're on Rails 7.1 or later. It's the modern, recommended approach.

---

## with_stream Pattern (Rails 7.1+)

This is the preferred approach for Rails 7.1+. It hijacks the connection and streams directly.

### with_stream Checklist

**Before streaming, verify ALL of these are present:**

- [ ] Rails 7.1+ (for older Rails, use ActionController::Live instead)
- [ ] Headers are set: `Content-Type`, `Cache-Control: no-cache`, `X-Accel-Buffering: no`
- [ ] `response.headers["rack.hijack"]` set to a proc that yields the hijacked stream
- [ ] Stream cleanup in `ensure` block: `stream.close if stream.respond_to?(:close)`
- [ ] Handle `IOError` for client disconnects within the thread

### Complete Controller Example

```ruby
require "securerandom"
require "ag_ui_protocol"

class AgUiController < ActionController::API
  def run
    encoder = AgUiProtocol::Encoder::EventEncoder.new(accept: request.headers["Accept"])
    thread_id = params[:thread_id] || SecureRandom.uuid
    run_id = params[:run_id] || SecureRandom.uuid

    with_stream(encoder.content_type) do |stream|
      # Start the run
      stream.write(encoder.encode(
        AgUiProtocol::Core::Events::RunStartedEvent.new(
          thread_id: thread_id,
          run_id: run_id
        )
      ))
      stream.flush if stream.respond_to?(:flush)

      # Stream your content
      message_id = SecureRandom.uuid
      stream.write(encoder.encode(
        AgUiProtocol::Core::Events::TextMessageStartEvent.new(message_id: message_id)
      ))
      stream.flush if stream.respond_to?(:flush)

      # Simulate agent processing
      sleep(1)

      stream.write(encoder.encode(
        AgUiProtocol::Core::Events::TextMessageContentEvent.new(
          message_id: message_id,
          delta: "Hello world!"
        )
      ))
      stream.flush if stream.respond_to?(:flush)

      stream.write(encoder.encode(
        AgUiProtocol::Core::Events::TextMessageEndEvent.new(message_id: message_id)
      ))
      stream.flush if stream.respond_to?(:flush)

      # End the run
      stream.write(encoder.encode(
        AgUiProtocol::Core::Events::RunFinishedEvent.new(
          thread_id: thread_id,
          run_id: run_id,
          result: { "status" => "ok" }
        )
      ))
      stream.flush if stream.respond_to?(:flush)

    rescue StandardError => e
      # Emit error event before re-raising
      encoder ||= AgUiProtocol::Encoder::EventEncoder.new(accept: request.headers["Accept"])
      stream.write(encoder.encode(
        AgUiProtocol::Core::Events::RunErrorEvent.new(message: e.message)
      ))
      raise

    ensure
      # Stream cleanup happens in with_stream via ensure
    end

    head :ok
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
          # Client disconnected
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

### The with_stream Helper Explained

The `with_stream` method does several things:

1. **Sets required headers:**
   - `Content-Type` — must match what the encoder advertises
   - `Cache-Control: no-cache` — prevents buffering on proxies
   - `X-Accel-Buffering: no` — disables nginx buffering

2. **Hijacks the connection:**
   - `rack.hijack` takes over the socket
   - Yields the stream object to the block
   - Runs in a separate thread

3. **Handles errors:**
   - `IOError` = client disconnected (not an error, just log it)
   - Exceptions in the thread get caught, logged, and stream is closed
   - The original exception is re-raised after the error event is written

4. **Always closes the stream:**
   - The `ensure` block guarantees cleanup even on errors

### Common Mistake: Forgetting to Flush

Without `stream.flush`, data may not reach the client immediately:

```ruby
# Good: flush immediately
stream.write(encoder.encode(event))
stream.flush if stream.respond_to?(:flush)

# Works but delays: no flush
stream.write(encoder.encode(event))
```

---

## ActionController::Live Pattern (Rails < 7.1)

If you're on an older Rails version, use `ActionController::Live`. It keeps the connection open but runs synchronously.

### ActionController::Live Checklist

**Before streaming, verify ALL of these are present:**

- [ ] Class declaration includes `ActionController::Live`: `class X < ActionController::API`, then `include ActionController::Live`
- [ ] Headers are set: `Content-Type`, `Cache-Control: no-cache`, `X-Accel-Buffering: no`
- [ ] Write using `response.stream.write(...)` — NOT a local variable named `stream`
- [ ] Close in `ensure` block: `response.stream.close if response.stream.respond_to?(:close)`
- [ ] Handle `IOError` for client disconnects

### Complete Controller Example

```ruby
require "securerandom"
require "ag_ui_protocol"

class AgUiController < ActionController::API
  include ActionController::Live

  def run
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    encoder = AgUiProtocol::Encoder::EventEncoder.new
    thread_id = params[:thread_id] || SecureRandom.uuid
    run_id = params[:run_id] || SecureRandom.uuid

    begin
      # Stream events using response.stream, NOT a local variable
      response.stream.write(encoder.encode(
        AgUiProtocol::Core::Events::RunStartedEvent.new(
          thread_id: thread_id,
          run_id: run_id
        )
      ))
      response.stream.flush if response.stream.respond_to?(:flush)

      message_id = SecureRandom.uuid
      response.stream.write(encoder.encode(
        AgUiProtocol::Core::Events::TextMessageStartEvent.new(message_id: message_id)
      ))
      response.stream.flush if response.stream.respond_to?(:flush)

      sleep(1)  # simulate processing

      response.stream.write(encoder.encode(
        AgUiProtocol::Core::Events::TextMessageContentEvent.new(
          message_id: message_id,
          delta: "Hello world!"
        )
      ))
      response.stream.flush if response.stream.respond_to?(:flush)

      response.stream.write(encoder.encode(
        AgUiProtocol::Core::Events::RunFinishedEvent.new(
          thread_id: thread_id,
          run_id: run_id
        )
      ))
      response.stream.flush if response.stream.respond_to?(:flush)

    rescue IOError
      Rails.logger.warn("Client disconnected")

    ensure
      response.stream.close if response.stream.respond_to?(:close)
    end

    head :ok
  end
end
```

### Key Differences from with_stream

| Aspect | ActionController::Live | with_stream |
|--------|------------------------|-------------|
| Concurrency | Blocks one thread per connection | Spawns new thread per request |
| Error in event | Can't emit after error | Can emit RunErrorEvent before re-raising |
| Cleanup | Must close stream manually | Automatic via ensure |
| Rails version | Any | 7.1+ |

---

## Required Headers (Both Patterns)

Every streaming response needs these headers:

```ruby
response.headers["Content-Type"] = encoder.content_type
response.headers["Cache-Control"] = "no-cache"
response.headers["X-Accel-Buffering"] = "no"
```

- **`Content-Type`** — SSE is `text/event-stream` by default, or negotiated
- **`Cache-Control: no-cache`** — prevents intermediate proxies from buffering
- **`X-Accel-Buffering: no`** — disables nginx buffering (critical for streaming)

---

## Route Configuration

```ruby
# config/routes.rb
Rails.application.routes.draw do
  post "/ag-ui/run", to: "ag_ui#run"
end
```

Your route should be POST since AG-UI typically sends a run request with `RunAgentInput`.

---

## Client Disconnect Handling

When a client closes the connection, you'll get an `IOError` when trying to write. Both patterns handle this:

**with_stream:**
```ruby
rescue IOError
  Rails.logger.warn("AG-UI client disconnected")
# stream.close happens in ensure
```

**ActionController::Live:**
```ruby
rescue IOError
  Rails.logger.warn("AG-UI client disconnected")
ensure
  stream.close
```

Don't try to emit events after a disconnect — the client is gone. Just clean up gracefully.

---

## Error Handling Flow

Always emit a `RunErrorEvent` before re-raising exceptions:

```ruby
rescue StandardError => e
  stream.write(encoder.encode(
    AgUiProtocol::Core::Events::RunErrorEvent.new(
      message: e.message,
      code: e.class.name
    )
  ))
  raise  # Re-raise so Rails handles it however your app configured
```

This way the client knows the run failed, even if they can't process the error visually.

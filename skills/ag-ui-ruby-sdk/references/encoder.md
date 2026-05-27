# EventEncoder

The `EventEncoder` converts event objects into SSE (Server-Sent Events) format for streaming to clients.

## The Wire Format

Events never go directly over the wire. They get encoded first:

```
data: {"type":"TEXT_MESSAGE_CONTENT","messageId":"m1","delta":"Hello"}\n\n
```

This is standard SSE format. Clients consume it via `EventSource` or similar.

## Creating an Encoder

```ruby
# Basic encoder (default text/event-stream)
encoder = AgUiProtocol::Encoder::EventEncoder.new

# With content negotiation
encoder = AgUiProtocol::Encoder::EventEncoder.new(accept: request.headers["Accept"])
```

### Constructor Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `accept` | `String\|nil` | no | Accept header for content negotiation |

### content_type Method

| Return | Description |
|---|---|
| `"text/event-stream"` | Default SSE content type |
| `"application/json"` | If accept header matches a known type |

## Encoding Events

```ruby
encoder = AgUiProtocol::Encoder::EventEncoder.new

event = AgUiProtocol::Core::Events::TextMessageContentEvent.new(
  message_id: "msg_123",
  delta: "Hello, world!"
)

encoded = encoder.encode(event)
# => "data: {\"type\":\"TEXT_MESSAGE_CONTENT\",\"messageId\":\"msg_123\",\"delta\":\"Hello, world!\"}\n\n"
```

### encode Method Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `event` | `BaseEvent` | yes | The event object to encode |

### encode Return Value

| Return | Description |
|---|---|
| `String` | SSE-formatted string: `data: {json}\n\n` |

## Complete Integration Pattern

```ruby
class AgUiController < ActionController::API
  def run
    encoder = AgUiProtocol::Encoder::EventEncoder.new(accept: request.headers["Accept"])
    response.headers["Content-Type"] = encoder.content_type

    with_stream do |stream|
      event = AgUiProtocol::Core::Events::RunStartedEvent.new(
        thread_id: thread_id,
        run_id: run_id
      )
      stream.write(encoder.encode(event))
      stream.flush if stream.respond_to?(:flush)
    end
  end
end
```

## Key Points

1. **One event per encoded string** - Each `encode()` call produces one SSE record
2. **Flush after write** - Call `stream.flush` if available to push data immediately
3. **Encode before writing** - The encoder handles JSON serialization and SSE formatting
4. **Content negotiation** - Pass the Accept header to support different client formats

## SSE Format Details

SSE is a simple text format:
```
data: {json}\n\n
```

The `\n\n` terminator signals end of the event record. Multiple events sent sequentially form a stream.

The encoder transforms:
- `message_id` → `messageId`
- `thread_id` → `threadId`
- Keys to camelCase
- Removes nil values

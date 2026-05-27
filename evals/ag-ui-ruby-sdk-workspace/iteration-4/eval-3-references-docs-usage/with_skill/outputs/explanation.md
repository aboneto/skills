# TextMessageStartEvent vs TextMessageChunkEvent

## TextMessageStartEvent

Signals the **start of a text message stream**. Used as part of the granular Start/Content/End pattern.

**Required attributes:**
- `message_id` (String) — Unique ID that must be reused by subsequent Content and End events

**Optional attributes:**
- `role` (String) — Defaults to `"assistant"`. Valid values: `"developer"`, `"system"`, `"assistant"`, `"user"`
- `timestamp` (Time|nil)
- `raw_event` (Object|nil)

```ruby
AgUiProtocol::Core::Events::TextMessageStartEvent.new(
  message_id: "m1",
  role: "assistant",
  timestamp: nil,
  raw_event: nil
)
```

---

## TextMessageChunkEvent

A **convenience event** that some clients auto-expand into Start/Content/End automatically.

**Required attributes:** None (all optional)

**Optional attributes:**
- `message_id` (String|nil) — Required on first chunk for a message
- `role` (String|nil) — Must be one of TEXT_MESSAGE_ROLE_VALUES
- `delta` (String|nil) — Text chunk
- `timestamp` (Time|nil)
- `raw_event` (Object|nil)

```ruby
AgUiProtocol::Core::Events::TextMessageChunkEvent.new(
  message_id: "m1",
  role: nil,
  delta: "Hello",
  timestamp: nil,
  raw_event: nil
)
```

---

## Key Differences

| Aspect | TextMessageStartEvent | TextMessageChunkEvent |
|--------|----------------------|-----------------------|
| Pattern | Start/Content/End granular | Single convenience event |
| Required attributes | `message_id` is required | None required |
| Use case | Fine-grained control over streaming | Simpler integration, auto-expanded by some clients |
| Role | Defaults to "assistant" | Must be set explicitly if needed |
| Granularity | Three separate events | One event replaces three |

Both events serve the same underlying purpose (streaming text), but `TextMessageStartEvent` is part of a structured three-event lifecycle while `TextMessageChunkEvent` is a simplified alternative that some clients automatically expand into the Start/Content/End sequence.

# TextMessageStartEvent vs TextMessageChunkEvent

Based on the AG-UI Ruby SDK reference documentation (`references/events.md`).

## TextMessageStartEvent

**What it marks:** The beginning of a text message stream. This is a formal signal that declares a new message is starting, with a unique `message_id` that will link together the full lifecycle of that message (Start → Content → End).

```ruby
AgUiProtocol::Core::Events::TextMessageStartEvent.new(
  message_id: "m1",
  role: nil,
  timestamp: nil,
  raw_event: nil
)
```

**Required attributes:**

| Attribute   | Required | Description |
|-------------|----------|-------------|
| `message_id` | yes      | Unique ID reused across Start, Content, and End events |
| `role`      | no       | Defaults to `"assistant"`. Valid: `"developer"`, `"system"`, `"assistant"`, `"user"` |

**Optional attributes (all events):** `timestamp`, `raw_event`

---

## TextMessageChunkEvent

**What it is:** A **convenience event** designed for simpler use cases. Some clients automatically expand a `TextMessageChunkEvent` into the full Start/Content/End sequence. This means you can emit a single chunk event instead of three separate ones.

```ruby
AgUiProtocol::Core::Events::TextMessageChunkEvent.new(
  message_id: nil,
  role: nil,
  delta: "Hello",
  timestamp: nil,
  raw_event: nil
)
```

**Attributes:**

| Attribute    | Required     | Description |
|--------------|--------------|-------------|
| `message_id` | no           | Required on the first chunk for a given message |
| `role`       | no           | Must be one of TEXT_MESSAGE_ROLE_VALUES |
| `delta`      | no           | Text chunk |
| `timestamp`  | no           | When created |
| `raw_event`  | no           | Original event if transformed |

Unlike `TextMessageStartEvent`, **none of the attributes are strictly required** — the event is deliberately flexible to accommodate streaming scenarios where message boundaries may not be known upfront.

---

## When to Use Each

| Scenario | Recommended Event |
|----------|-------------------|
| Need explicit message boundaries and control over the full lifecycle | `TextMessageStartEvent` + `TextMessageContentEvent` + `TextMessageEndEvent` |
| Prefer simplicity or working with clients that auto-expand chunks | `TextMessageChunkEvent` |
| Streaming text where you do not know the full message length in advance | `TextMessageChunkEvent` |
| Need to associate role, track message state explicitly | `TextMessageStartEvent` pattern |

The SDK documentation notes: *"Use Start/Content/End for granular control. Use Chunk for simplicity (some clients auto-expand)."*

---

## Key Difference Summary

| | TextMessageStartEvent | TextMessageChunkEvent |
|---|---|---|
| **Purpose** | Formal start of a message stream | Convenience wrapper, auto-expanded by some clients |
| **message_id** | **Required** | Optional (required on first chunk only) |
| **Role declaration** | Optional, defaults to "assistant" | Optional |
| **delta** | N/A (no content in start) | Optional text chunk |
| **Strictness** | Enforces message structure | More relaxed/flexible |

---

## Reference

This explanation is based on `skills/ag-ui-ruby-sdk/references/events.md` from the AG-UI Ruby SDK skill.
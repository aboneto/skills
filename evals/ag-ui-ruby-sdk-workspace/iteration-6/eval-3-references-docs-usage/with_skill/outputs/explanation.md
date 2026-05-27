# TextMessageStartEvent vs TextMessageChunkEvent

Both inherit from `BaseEvent` and belong to the **Text Message Events** group. They share the common `BaseEvent` properties plus their own specific attributes.

---

## Common (inherited from `BaseEvent`)

| Property | Type | Description |
|---|---|---|
| `type` | `String` | Event type constant |
| `timestamp` | `Time\|nil` | When the event was created |
| `raw_event` | `Object\|nil` | Original event if transformed |

---

## TextMessageStartEvent

**Purpose:** Signals the start of a text message stream. Must be paired with `TextMessageContentEvent` and `TextMessageEndEvent` via a shared `message_id`.

```ruby
AgUiProtocol::Core::Events::TextMessageStartEvent.new(
  message_id: "m1",
  role: nil,         # optional, defaults to "assistant"
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `message_id` | `String` | **yes** | Unique ID — reuse for Content and End events |
| `role` | `String` | no | Defaults to `"assistant"`. Valid: `developer`, `system`, `assistant`, `user` |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

---

## TextMessageChunkEvent

**Purpose:** Convenience event that combines Start + Content semantics into a single message. Some clients expand it into Start/Content/End automatically.

```ruby
AgUiProtocol::Core::Events::TextMessageChunkEvent.new(
  message_id: "m1",
  role: nil,
  delta: "Hello",
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `message_id` | `String\|nil` | no | Required **on first chunk** for a message |
| `role` | `String\|nil` | no | Must be one of: `developer`, `system`, `assistant`, `user`, `reasoning` |
| `delta` | `String\|nil` | no | Text chunk |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

---

## Key Differences

| Aspect | TextMessageStartEvent | TextMessageChunkEvent |
|---|---|---|
| **Role in stream** | **Mandatory opening** of a 3-event sequence (Start → Content* → End) | **Self-contained** convenience event; clients may expand into Start/Content/End |
| `message_id` | **Required** `String` | **Optional** `String\|nil` — only needed on first chunk |
| `role` | Optional `String`, defaults to `"assistant"` | Optional `String\|nil`, no default, includes `"reasoning"` as valid value |
| `delta` | **Absent** | Optional `String\|nil` — carries the text content |
| **Cardinality** | Exactly one per message | One or many (each chunk can be emitted independently) |
| **Relationship** | Links Content and End events via `message_id` | Standalone — does not require companion events |
| **Protocol pattern** | `Start → Content(1..n) → End` | `Chunk(1..n)` — simpler, less strict |

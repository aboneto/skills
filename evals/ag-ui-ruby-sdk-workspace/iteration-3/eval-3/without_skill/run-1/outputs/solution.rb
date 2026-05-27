# AG-UI Protocol: TextMessageStartEvent vs TextMessageChunkEvent

## 1. TextMessageStartEvent

This event **marks the beginning of a new text message stream**. It signals to the client that a message is starting and provides all the necessary metadata to prepare for receiving content.

**Required attributes:**
- `message_id` — unique identifier linking all events for this message
- `role` — the speaker (e.g., "assistant", "user", "system")
- `content_type` — the type of content being streamed (typically "text" or "audio")

The Start event establishes the message context before any content arrives.

---

## 2. TextMessageChunkEvent

This is a **convenience event** that **combines Start + Content + End into a single event** for simpler streaming use cases. It allows sending incremental text without the full explicit pattern.

**Attributes:**
- `message_id` — links to the parent message (required)
- `index` — the chunk sequence number within the message
- `content` — the actual text content of the chunk
- `is_complete` — boolean indicating if this is the final chunk (implicitly ends the message)

---

## 3. When to Use Each

| Use convenience chunk when: | Use explicit Start/Content/End pattern when: |
|------------------------------|-----------------------------------------------|
| Simple text streaming without rich metadata | You need to stream additional metadata per message |
| Minimizing event overhead | You need Content events with different content types |
| Content arrives in small incremental chunks | You need to interleave multiple content types |
| Building quickly without complex state | You need separate control over when content is "added" vs message "ends" |

The convenience chunk is ideal for straightforward streaming. The explicit pattern provides more control and is necessary for multi-modal content.

---

## 4. How message_id Links Events

The `message_id` is the **shared key** across all events belonging to the same logical message:

```
TextMessageStartEvent (message_id: "abc-123")
         ↓
TextMessageContentEvent (message_id: "abc-123")
TextMessageContentEvent (message_id: "abc-123")
         ↓
TextMessageEndEvent (message_id: "abc-123")
```

With convenience chunks, the pattern collapses:

```
TextMessageChunkEvent (message_id: "abc-123", index: 0, content: "Hello")
TextMessageChunkEvent (message_id: "abc-123", index: 1, content: " world")
TextMessageChunkEvent (message_id: "abc-123", index: 2, content: "!", is_complete: true)
```

The client uses `message_id` to group and order all events into the final coherent message.

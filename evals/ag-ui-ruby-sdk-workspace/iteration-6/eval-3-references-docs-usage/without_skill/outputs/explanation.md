# Streaming Protocol Events: `message-start` vs `message-chunk`

## Overview

In streaming protocols (e.g., Server-Sent Events, WebSocket streams, HTTP chunked transfer, custom RPC streams), messages are often split into lifecycle events. `message-start` and `message-chunk` are two such events that separate *metadata* from *payload delivery*.

## `message-start` Event

Fires when a new message begins transmission. Carries **message-level metadata** but **no (or minimal) payload content**.

| Attribute | Type | Description |
|---|---|---|
| `id` | string | Unique identifier for the message |
| `stream_id` | string | Identifies the stream this message belongs to |
| `type` | string | Message type or category (e.g., `"text"`, `"json"`, `"binary"`) |
| `timestamp` | integer | Unix timestamp (ms) of when the message started |
| `content_type` | string | MIME type of the payload (e.g., `"application/json"`) |
| `content_length` | integer | Total expected payload length (if known a priori) |
| `metadata` | object | Arbitrary key-value headers or context |
| `encoding` | string | Transfer encoding (e.g., `"gzip"`, `"base64"`) |

## `message-chunk` Event

Fires for each discrete fragment of the payload body. Carries **payload data** but **no (or minimal) message metadata**.

| Attribute | Type | Description |
|---|---|---|
| `message_id` | string | Links the chunk to its parent `message-start` |
| `sequence` | integer | Ordinal position in the chunk sequence (0-based) |
| `offset` | integer | Byte offset from the start of the payload |
| `data` | string/buffer | The actual chunk payload (text or binary) |
| `size` | integer | Size of this chunk in bytes |
| `is_final` | boolean | `true` if this is the last chunk |

## Key Differences

| Dimension | `message-start` | `message-chunk` |
|---|---|---|
| **Purpose** | Signal beginning and provide context | Deliver incremental payload fragments |
| **Content carried** | Metadata (headers, type, length) | Actual payload bytes/text |
| **Cardinality** | Exactly one per message | Zero or more per message |
| **Replay semantics** | Can be replayed to reinitialize state | Must be replayed in order; may fail if start is missing |
| **Error handling** | If lost, the entire message is unrecoverable | If lost, only that segment must be retransmitted |
| **Timing** | Emitted once at the start | Emitted repeatedly as data becomes available |
| **Idempotency** | Not idempotent (starting twice is an error) | Idempotent (chunks can be retried individually) |

## Typical Stream Flow

```
message-start  ──►  { id: "msg_1", type: "json", content_length: 3000 }
message-chunk  ──►  { message_id: "msg_1", sequence: 0, data: "{ \"us" }
message-chunk  ──►  { message_id: "msg_1", sequence: 1, data: "ers\": [" }
message-chunk  ──►  { message_id: "msg_1", sequence: 2, data: "1,2,3] }" }
message-chunk  ──►  { message_id: "msg_1", sequence: 3, data: "", is_final: true }
```

## Why Two Events?

1. **Metadata-first delivery** — consumers can inspect headers (routing, auth, content type) before committing to buffering the body.
2. **Backpressure** — a consumer can reject a message at `message-start` without ever receiving chunks.
3. **Partial retry** — if a chunk is lost, only that chunk (not the whole message) needs retransmission.
4. **Streaming efficiency** — chunks can be emitted as soon as sub-milligram pieces of data arrive, without waiting for the full payload to materialise.

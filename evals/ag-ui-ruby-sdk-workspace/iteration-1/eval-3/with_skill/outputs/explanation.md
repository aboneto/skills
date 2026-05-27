# Difference between TextMessageStartEvent and TextMessageChunkEvent

This document explains the differences between `TextMessageStartEvent` and `TextMessageChunkEvent` in the AG-UI Ruby SDK (`ag-ui-protocol` gem), along with the attributes required by each.

---

## 1. Architectural & Behavioral Differences

The primary difference lies in the streaming pattern they support:

### **TextMessageStartEvent**
- **Pattern:** Part of the **Start/Content/End** granular streaming pattern.
- **Purpose:** Specifically signals the **beginning** of a new text message stream. It initiates a message on the client-side.
- **Workflow:** In a standard stream, a single `TextMessageStartEvent` is sent first, followed by one or more `TextMessageContentEvent`s (carrying the incremental chunks of text), and completed with a single `TextMessageEndEvent`.
- **Use Case:** Choose this when you need fine-grained control over the lifecycle of a message (e.g., when you need to explicitly demarcate exactly when a message begins and ends, or when sending metadata specifically at the start).

### **TextMessageChunkEvent**
- **Pattern:** Part of the **Chunk-based** (or single-event) streaming pattern.
- **Purpose:** Serves as a **convenience event** that combines message identification, role declaration, and content delivery into a single event type.
- **Workflow:** The agent simply streams one or more `TextMessageChunkEvent`s.
- **Client Behavior:** Many clients/consumers are designed to automatically expand these chunks into the corresponding start, content, and end events internally.
- **Use Case:** Choose this for simplicity when you do not need granular control over the start and end phases of the message lifecycle.

---

## 2. Attributes and Requirements

Both events inherit from `BaseEvent` and thus share the common attributes of any AG-UI event, but they differ significantly in their class-specific parameters.

### **TextMessageStartEvent**

Class: `AgUiProtocol::Core::Events::TextMessageStartEvent`

#### Common (Inherited) Attributes:
- **`type`** (`String`): Automatically set to `"TEXT_MESSAGE_START"`.
- **`timestamp`** (`Time|nil`): Optional. Indicates when the event was created.
- **`raw_event`** (`Object|nil`): Optional. The original event if this was transformed from another format.

#### Class-Specific Attributes:
| Attribute | Type | Required | Description |
|---|---|---|---|
| **`message_id`** | `String` | **Yes** | A unique identifier for the message. Subsequent content and end events must use the exact same ID. |
| **`role`** | `String` | **No** (Defaults to `"assistant"`) | The role associated with the message. Must be one of: `"developer"`, `"system"`, `"assistant"`, or `"user"`. |

---

### **TextMessageChunkEvent**

Class: `AgUiProtocol::Core::Events::TextMessageChunkEvent`

#### Common (Inherited) Attributes:
- **`type`** (`String`): Automatically set to `"TEXT_MESSAGE_CHUNK"`.
- **`timestamp`** (`Time|nil`): Optional. Indicates when the event was created.
- **`raw_event`** (`Object|nil`): Optional. The original event if this was transformed from another format.

#### Class-Specific Attributes:
| Attribute | Type | Required | Description |
|---|---|---|---|
| **`message_id`** | `String\|nil` | **No** (But required on the first chunk) | Unique identifier for the message. While technically optional in the constructor, it must be provided on the first chunk for the message to be properly associated. |
| **`role`** | `String\|nil` | **No** | The role of the sender. Must be a valid value in `TEXT_MESSAGE_ROLE_VALUES`. |
| **`delta`** | `String\|nil` | **No** | The text chunk or increment to append to the message. |

---

## Summary Comparison

| Metric | `TextMessageStartEvent` | `TextMessageChunkEvent` |
|---|---|---|
| **Streaming Style** | Granular (Start/Content/End) | Convenience (Chunk-based) |
| **`message_id`** | **Required** (must be a non-nil String) | **Optional** (Constructor allows `nil`, but required on first chunk) |
| **`role`** | Optional (defaults to `"assistant"`) | Optional (`nil` by default) |
| **`delta`** | Not applicable (not supported) | Optional (`nil` by default, represents text increment) |
| **Event Type String** | `"TEXT_MESSAGE_START"` | `"TEXT_MESSAGE_CHUNK"` |

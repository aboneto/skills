### TextMessageStartEvent vs. TextMessageChunkEvent in AG-UI Ruby SDK

Here is the explanation of the differences between `TextMessageStartEvent` and `TextMessageChunkEvent`, along with their required attributes.

---

### 1. Key Differences

* **`TextMessageStartEvent`**:
  * **Purpose**: Signals the **initialization** of a new text message.
  * **Role**: It tells the receiving client or UI component that a new message stream has begun. It sets up the metadata context (like message identifier, participant role, and timestamp) but does not carry the actual message body/text content.
  * **Frequency**: Sent exactly once at the beginning of a message generation.

* **`TextMessageChunkEvent`**:
  * **Purpose**: Signals the **incremental arrival** of text content (a chunk/delta) for an active message.
  * **Role**: It carries the actual textual content segments as they are streamed. The client appends the text provided in this event to the message container initialized by the corresponding `TextMessageStartEvent`.
  * **Frequency**: Sent multiple times (iteratively) as the text content is generated and streamed, until the message is complete.

---

### 2. Required Attributes

#### **TextMessageStartEvent**
This event initializes the message and requires the following attributes:
* **`message_id`** (String): A unique identifier for the message. This ID is crucial as it links all subsequent chunk events to this specific message.
* **`role`** (String): The sender's role (e.g., `'assistant'`, `'user'`, `'system'`).
* **`index`** (Integer): The index of the message in the sequence of messages for a given turn.

*Optional/Contextual:*
* **`timestamp`** (Integer / Float / DateTime): The timestamp when the message creation started.

#### **TextMessageChunkEvent**
This event streams chunks of text and requires the following attributes:
* **`message_id`** (String): The unique identifier of the message this chunk belongs to. It must match the `message_id` sent in the initial `TextMessageStartEvent` to ensure the content is appended to the correct message.
* **`text`** (String): The actual chunk/delta of text content being sent. This is appended to the accumulated text on the client side.
* **`index`** (Integer): The sequence or message index to ensure correct ordering.

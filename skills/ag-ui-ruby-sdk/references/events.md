# Events

The AG-UI Ruby SDK streams events one direction: agent to client. Each event inherits from `BaseEvent` and serializes to SSE via `EventEncoder`.

## BaseEvent — the parent

```ruby
AgUiProtocol::Core::Events::BaseEvent.new(
  type: "RUN_STARTED",
  timestamp: nil,
  raw_event: nil
)
```

**Common properties across all events:**

| Property | Type | Description |
|---|---|---|
| `type` | `String` | Event type constant (e.g., `RUN_STARTED`) |
| `timestamp` | `Time|nil` | When the event was created |
| `raw_event` | `Object|nil` | Original event if transformed |

All events implement `to_h` → `as_json` → `to_json` for serialization. camelCase conversion is automatic.

## EventType module

Contains all event type constants:

```ruby
# Lifecycle
RUN_STARTED, RUN_FINISHED, RUN_ERROR, STEP_STARTED, STEP_FINISHED

# Text messages
TEXT_MESSAGE_START, TEXT_MESSAGE_CONTENT, TEXT_MESSAGE_END, TEXT_MESSAGE_CHUNK

# Tool calls
TOOL_CALL_START, TOOL_CALL_ARGS, TOOL_CALL_END, TOOL_CALL_CHUNK, TOOL_CALL_RESULT

# Thinking
THINKING_START, THINKING_END, THINKING_TEXT_MESSAGE_START, THINKING_TEXT_MESSAGE_CONTENT, THINKING_TEXT_MESSAGE_END

# Reasoning
REASONING_START, REASONING_MESSAGE_START, REASONING_MESSAGE_CONTENT, REASONING_MESSAGE_END, REASONING_MESSAGE_CHUNK, REASONING_END, REASONING_ENCRYPTED_VALUE

# State management
STATE_SNAPSHOT, STATE_DELTA, MESSAGES_SNAPSHOT, ACTIVITY_SNAPSHOT, ACTIVITY_DELTA

# Special
RAW, CUSTOM
```

---

## Lifecycle Events

### RunStartedEvent

**Must be emitted FIRST** — before any other event. Signals a new agent run.

```ruby
AgUiProtocol::Core::Events::RunStartedEvent.new(
  thread_id: "t1",
  run_id: "r1",
  parent_run_id: nil,
  input: nil,
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `thread_id` | `String` | yes | Conversation thread ID |
| `run_id` | `String` | yes | Unique run ID |
| `parent_run_id` | `String\|nil` | no | Lineage pointer for branching/time travel |
| `input` | `RunAgentInput\|nil` | no | The agent input payload for this run |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

### RunFinishedEvent

**Must be emitted LAST** on success. Signals run completed. Use either `result:` (arbitrary hash) or `outcome:` (typed outcome object), but not both.

```ruby
# Success
AgUiProtocol::Core::Events::RunFinishedEvent.new(
  thread_id: "t1",
  run_id: "r1",
  outcome: AgUiProtocol::Core::Events::RunFinishedSuccessOutcome.new
)

# With interrupt
AgUiProtocol::Core::Events::RunFinishedEvent.new(
  thread_id: "t1",
  run_id: "r1",
  outcome: AgUiProtocol::Core::Events::RunFinishedInterruptOutcome.new(
    interrupts: [AgUiProtocol::Core::Types::Interrupt.new(id: "int_1", reason: "input_required")]
  )
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `thread_id` | `String` | yes | Conversation thread ID |
| `run_id` | `String` | yes | Unique run ID |
| `result` | `Object\|nil` | no | Arbitrary result data (mutually exclusive with `outcome`) |
| `outcome` | `RunFinishedSuccessOutcome\|RunFinishedInterruptOutcome\|nil` | no | Typed outcome (mutually exclusive with `result`) |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

### RunFinishedSuccessOutcome

Signals a successful run completion. Used as the `outcome:` value in `RunFinishedEvent`.

```ruby
AgUiProtocol::Core::Events::RunFinishedSuccessOutcome.new
```

| Property | Type | Required | Description |
|---|---|---|---|
| `type` | `String` | auto | Always `"success"` |

### RunFinishedInterruptOutcome

Signals that the run was interrupted and requires human involvement before resuming. Used as the `outcome:` value in `RunFinishedEvent`.

```ruby
outcome = AgUiProtocol::Core::Events::RunFinishedInterruptOutcome.new(
  interrupts: [
    AgUiProtocol::Core::Types::Interrupt.new(
      id: "int_1",
      reason: "input_required",
      message: "Please provide your API key",
      tool_call_id: nil,
      response_schema: { "type" => "object", "properties" => { "api_key" => { "type" => "string" } } },
      expires_at: 1.hour.from_now.iso8601,
      metadata: { "step" => "authentication" }
    )
  ]
)

stream.write(encoder.encode(
  AgUiProtocol::Core::Events::RunFinishedEvent.new(
    thread_id: thread_id,
    run_id: run_id,
    outcome: outcome
  )
))
```

| Property | Type | Required | Description |
|---|---|---|---|
| `type` | `String` | auto | Always `"interrupt"` |
| `interrupts` | `Array<Interrupt>` | yes | Interrupts requiring resolution |

**To resume:** the client sends a `ResumeEntry` back via `RunAgentInput.forwarded_props`:

```ruby
resume = AgUiProtocol::Core::Types::ResumeEntry.new(
  interrupt_id: "int_1",
  status: "resolved",
  payload: { "api_key" => "user-provided-key" }
)
```

### RunErrorEvent

**Must be emitted LAST** on failure. Signals a run error.

```ruby
AgUiProtocol::Core::Events::RunErrorEvent.new(
  message: "Connection timeout",
  code: "TIMEOUT_ERROR",
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `message` | `String` | yes | Human-readable error description |
| `code` | `String\|nil` | no | Machine-readable error code |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

**Usage:**
```ruby
rescue StandardError => e
  stream.write(encoder.encode(
    AgUiProtocol::Core::Events::RunErrorEvent.new(message: e.message, code: e.class.name)
  ))
  raise
```

Emit BEFORE re-raising so the client knows what happened.

### StepStartedEvent

Signals the start of a named step within a run.

```ruby
AgUiProtocol::Core::Events::StepStartedEvent.new(
  step_name: "searching",
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `step_name` | `String` | yes | Human-readable step name |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

### StepFinishedEvent

Signals completion of a named step.

```ruby
AgUiProtocol::Core::Events::StepFinishedEvent.new(
  step_name: "searching",
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `step_name` | `String` | yes | Must match the corresponding StepStartedEvent |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

---

## Text Message Events

All text messages share a `message_id` that links Start to Content to End together.

### TextMessageStartEvent

Signals the start of a text message stream.

```ruby
AgUiProtocol::Core::Events::TextMessageStartEvent.new(
  message_id: "m1",
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `message_id` | `String` | yes | Unique ID - reuse this for Content and End events |
| `role` | `String` | no | Defaults to `"assistant"` |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

Valid roles: `"developer"`, `"system"`, `"assistant"`, `"user"`

### TextMessageContentEvent

A chunk of streaming text content.

```ruby
AgUiProtocol::Core::Events::TextMessageContentEvent.new(
  message_id: "m1",
  delta: "Hello, ",
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `message_id` | `String` | yes | Must match the StartEvent |
| `delta` | `String` | yes | Non-empty text chunk |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

**Raises** `ArgumentError` if `delta` is nil or empty.

### TextMessageEndEvent

Signals the end of a text message stream.

```ruby
AgUiProtocol::Core::Events::TextMessageEndEvent.new(
  message_id: "m1",
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `message_id` | `String` | yes | Must match the StartEvent |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

### TextMessageChunkEvent

**Convenience event** - some clients expand this into Start/Content/End automatically.

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
| `message_id` | `String\|nil` | no | Required on first chunk for a message |
| `role` | `String\|nil` | no | Must be one of TEXT_MESSAGE_ROLE_VALUES (developer, system, assistant, user, reasoning) |
| `delta` | `String\|nil` | no | Text chunk |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

---

## Tool Call Events

All tool call events share a `tool_call_id` that links Start to Args to End together.

### ToolCallStartEvent

Signals the start of a tool call.

```ruby
AgUiProtocol::Core::Events::ToolCallStartEvent.new(
  tool_call_id: "tc1",
  tool_call_name: "web_search",
  parent_message_id: nil,
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `tool_call_id` | `String` | yes | Unique ID - reuse for Args and End events |
| `tool_call_name` | `String` | yes | Name of the tool being called |
| `parent_message_id` | `String\|nil` | no | ID of the parent message |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

### ToolCallArgsEvent

A chunk of streaming argument data.

```ruby
AgUiProtocol::Core::Events::ToolCallArgsEvent.new(
  tool_call_id: "tc1",
  delta: '{"q":"AG-UI"}',
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `tool_call_id` | `String` | yes | Must match the StartEvent |
| `delta` | `String` | yes | Non-empty argument chunk |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

**Raises** `ArgumentError` if `delta` is nil or empty.

### ToolCallEndEvent

Signals the end of a tool call.

```ruby
AgUiProtocol::Core::Events::ToolCallEndEvent.new(
  tool_call_id: "tc1",
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `tool_call_id` | `String` | yes | Must match the StartEvent |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

### ToolCallChunkEvent

**Convenience event** - some clients expand this into Start/Args/End automatically.

```ruby
AgUiProtocol::Core::Events::ToolCallChunkEvent.new(
  tool_call_id: "tc1",
  tool_call_name: "web_search",
  parent_message_id: nil,
  delta: '{"q":"AG-UI"}',
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `tool_call_id` | `String\|nil` | no | Required on first chunk |
| `tool_call_name` | `String\|nil` | no | Required on first chunk |
| `parent_message_id` | `String\|nil` | no | ID of parent message |
| `delta` | `String\|nil` | no | Argument data chunk |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

### ToolCallResultEvent

The result/output of a tool execution.

```ruby
AgUiProtocol::Core::Events::ToolCallResultEvent.new(
  message_id: "m1",
  tool_call_id: "tc1",
  content: "Found 42 results",
  role: "tool",
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `message_id` | `String` | yes | Conversation message this result belongs to |
| `tool_call_id` | `String` | yes | Matches the ToolCallStartEvent |
| `content` | `String` | yes | The tool output |
| `role` | `String\|nil` | no | Usually "tool", raises if other value |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

---

## Thinking Events

### ThinkingStartEvent

```ruby
AgUiProtocol::Core::Events::ThinkingStartEvent.new(
  title: "analyzing query",
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `title` | `String\|nil` | no | Title of the thinking step |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

### ThinkingEndEvent

```ruby
AgUiProtocol::Core::Events::ThinkingEndEvent.new(
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

### ThinkingTextMessageStartEvent

```ruby
AgUiProtocol::Core::Events::ThinkingTextMessageStartEvent.new(
  timestamp: nil,
  raw_event: nil
)
````

No properties besides the common ones.

### ThinkingTextMessageContentEvent

```ruby
AgUiProtocol::Core::Events::ThinkingTextMessageContentEvent.new(
  delta: "The user wants...",
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `delta` | `String` | yes | Non-empty thinking text chunk |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

**Raises** `ArgumentError` if `delta` is nil or empty.

### ThinkingTextMessageEndEvent

```ruby
AgUiProtocol::Core::Events::ThinkingTextMessageEndEvent.new(
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `timestamp` | `Time|nil` | no | When created |
| `raw_event` | `Object|nil` | no | Original event if transformed |

---

## Reasoning Events

These events convey structured reasoning blocks emitted by an agent, including streaming reasoning messages and encrypted reasoning values.

### ReasoningStartEvent

```ruby
AgUiProtocol::Core::Events::ReasoningStartEvent.new(
  message_id: "reason_1",
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `message_id` | `String` | yes | Unique identifier for the reasoning message |
| `timestamp` | `Time|nil` | no | When created |
| `raw_event` | `Object|nil` | no | Original event if transformed |

### ReasoningMessageStartEvent

```ruby
AgUiProtocol::Core::Events::ReasoningMessageStartEvent.new(
  message_id: "reason_msg_1",
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `message_id` | `String` | yes | Unique identifier |
| `role` | `String` | auto | Always `"reasoning"` |
| `timestamp` | `Time|nil` | no | When created |
| `raw_event` | `Object|nil` | no | Original event if transformed |

### ReasoningMessageContentEvent

```ruby
AgUiProtocol::Core::Events::ReasoningMessageContentEvent.new(
  message_id: "reason_msg_1",
  delta: "step 1...",
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `message_id` | `String` | yes | Must match the ReasoningMessageStartEvent |
| `delta` | `String` | yes | Non-empty reasoning content chunk |
| `timestamp` | `Time|nil` | no | When created |
| `raw_event` | `Object|nil` | no | Original event if transformed |

**Raises** `ArgumentError` if `delta` is nil or empty.

### ReasoningMessageEndEvent

```ruby
AgUiProtocol::Core::Events::ReasoningMessageEndEvent.new(
  message_id: "reason_msg_1",
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `message_id` | `String` | yes | Must match the ReasoningMessageStartEvent |
| `timestamp` | `Time|nil` | no | When created |
| `raw_event` | `Object|nil` | no | Original event if transformed |

### ReasoningMessageChunkEvent

**Convenience event** - some clients expand this into Start/Content/End automatically.

```ruby
AgUiProtocol::Core::Events::ReasoningMessageChunkEvent.new(
  message_id: "reason_msg_1",
  delta: "step 1...",
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `message_id` | `String|nil` | no | Required on first chunk |
| `delta` | `String|nil` | no | Reasoning content chunk |
| `timestamp` | `Time|nil` | no | When created |
| `raw_event` | `Object|nil` | no | Original event if transformed |

### ReasoningEndEvent

```ruby
AgUiProtocol::Core::Events::ReasoningEndEvent.new(
  message_id: "reason_1",
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `message_id` | `String` | yes | Must match the ReasoningStartEvent |
| `timestamp` | `Time|nil` | no | When created |
| `raw_event` | `Object|nil` | no | Original event if transformed |

### ReasoningEncryptedValueEvent

```ruby
AgUiProtocol::Core::Events::ReasoningEncryptedValueEvent.new(
  subtype: "tool-call",
  entity_id: "tc_1",
  encrypted_value: "encrypted...",
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `subtype` | `String` | yes | Free-form string; protocol values are "tool-call" or "message" |
| `entity_id` | `String` | yes | ID of the entity being encrypted |
| `encrypted_value` | `String` | yes | The encrypted value |
| `timestamp` | `Time|nil` | no | When created |
| `raw_event` | `Object|nil` | no | Original event if transformed |

**When to use it:** When zero-data-retention (ZDR) mode is enabled, reasoning content must be encrypted before emission. Use this event to wrap an encrypted reasoning value referenced by a tool call or message.

```ruby
# Encrypt reasoning content (ZDR mode) — agent side
stream.write(encoder.encode(
  AgUiProtocol::Core::Events::ReasoningEncryptedValueEvent.new(
    subtype: "tool-call",
    entity_id: tool_call_id,
    encrypted_value: encrypt(reasoning_content)
  )
))
```

---

## State Management Events

### StateSnapshotEvent

```ruby
AgUiProtocol::Core::Events::StateSnapshotEvent.new(
  snapshot: { "counter" => 0 },
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `snapshot` | `Object` | yes | Complete state hash |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

### StateDeltaEvent

```ruby
AgUiProtocol::Core::Events::StateDeltaEvent.new(
  delta: [
    { "op" => "replace", "path" => "/counter", "value" => 1 }
  ],
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `delta` | `Array<Object>` | yes | JSON Patch operations (RFC 6901) |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

JSON Patch operations: add, remove, replace, move, copy, test

### MessagesSnapshotEvent

```ruby
AgUiProtocol::Core::Events::MessagesSnapshotEvent.new(
  messages: [msg1, msg2],
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `messages` | `Array<BaseMessage>` | yes | All messages in conversation |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

**Raises** `ArgumentError` if `messages` is not an Array of BaseMessage.

Useful on client reconnect to sync full conversation state.

### ActivitySnapshotEvent

```ruby
AgUiProtocol::Core::Events::ActivitySnapshotEvent.new(
  message_id: "activity_1",
  activity_type: "SEARCH",
  content: { "query" => "...", "results" => [] },
  replace: true,
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `message_id` | `String` | yes | Activity message ID |
| `activity_type` | `String` | yes | Discriminator for renderer selection |
| `content` | `Object` | yes | Structured payload |
| `replace` | `Boolean` | no | If false, ignored if message_id already exists |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

### ActivityDeltaEvent

```ruby
AgUiProtocol::Core::Events::ActivityDeltaEvent.new(
  message_id: "activity_1",
  activity_type: "SEARCH",
  patch: [
    { "op" => "replace", "path" => "/results_count", "value" => 42 }
  ],
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `message_id` | `String` | yes | Must match the corresponding snapshot |
| `activity_type` | `String` | yes | Must match the snapshot type |
| `patch` | `Array<Object>` | yes | JSON Patch operations |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

---

## Special Events

### RawEvent

```ruby
AgUiProtocol::Core::Events::RawEvent.new(
  event: { "type" => "external", "data" => {} },
  source: "external_service",
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `event` | `Object` | yes | Original event data |
| `source` | `String\|nil` | no | Source of the event |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

### CustomEvent

```ruby
AgUiProtocol::Core::Events::CustomEvent.new(
  name: "my_event",
  value: { "any" => "data" },
  timestamp: nil,
  raw_event: nil
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `name` | `String` | yes | Custom event name |
| `value` | `Object` | yes | Custom event data |
| `timestamp` | `Time\|nil` | no | When created |
| `raw_event` | `Object\|nil` | no | Original event if transformed |

---

## Complete Event Order

Every run follows this pattern:

```
1. RunStartedEvent (FIRST)
2. Optional: StepStartedEvent
3. Optional: message events (TextMessageStart -> Content* -> End)
4. Optional: tool events (ToolCallStart -> Args* -> End)
5. Optional: Thinking events
6. Optional: State events
7. Optional: ToolCallResultEvent
8. Optional: StepFinishedEvent
9. RunFinishedEvent OR RunErrorEvent (LAST)
```

Always start with RunStartedEvent. Always end with RunFinishedEvent (success) or RunErrorEvent (failure).

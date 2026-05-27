# Types

The AG-UI Ruby SDK types represent the data structures used in agent-user communication. All types inherit from `Model` and provide `to_h`, `as_json`, and `to_json` methods.

## Type Hierarchy

```
Model (base)
├── BaseMessage
│   ├── UserMessage
│   ├── AssistantMessage
│   ├── DeveloperMessage
│   ├── SystemMessage
│   ├── ToolMessage
│   └── ReasoningMessage
├── ActivityMessage (standalone)
├── FunctionCall
├── ToolCall
├── Tool
├── Context
├── RunAgentInput
├── Interrupt
├── ResumeEntry
├── TextInputContent
├── BinaryInputContent
├── ImageInputContent
├── AudioInputContent
├── VideoInputContent
├── DocumentInputContent
├── InputContentDataSource
└── InputContentUrlSource
```

---

## Message Types

### UserMessage

The primary message type for user input. Supports plain text OR multimodal content.

```ruby
# Plain text
AgUiProtocol::Core::Types::UserMessage.new(
  id: "user_1",
  content: "Hello, world!"
)

# Multimodal (text + image)
AgUiProtocol::Core::Types::UserMessage.new(
  id: "user_2",
  content: [
    AgUiProtocol::Core::Types::TextInputContent.new(text: "Describe this"),
    AgUiProtocol::Core::Types::BinaryInputContent.new(
      mime_type: "image/png",
      url: "https://example.com/cat.png"
    )
  ]
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | yes | Unique message identifier |
| `content` | `String\|Array` | yes | Plain string OR array of TextInputContent/BinaryInputContent |
| `name` | `String\|nil` | no | Optional sender name |
| `role` | `String` | auto | Always `"user"` |

### AssistantMessage

Represents an assistant response. Can include tool_calls.

```ruby
AgUiProtocol::Core::Types::AssistantMessage.new(
  id: "asst_1",
  content: "I'll search for that.",
  tool_calls: [
    AgUiProtocol::Core::Types::ToolCall.new(
      id: "tc_1",
      function: { name: "web_search", arguments: '{"q":"..."}' }
    )
  ]
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | yes | Unique message identifier |
| `content` | `Object\|nil` | no | Text content or nil if only tool_calls |
| `tool_calls` | `Array<ToolCall>\|nil` | no | Array of tool calls made |
| `name` | `String\|nil` | no | Optional sender name |
| `role` | `String` | auto | Always `"assistant"` |

### DeveloperMessage

System-level instructions from a developer.

```ruby
AgUiProtocol::Core::Types::DeveloperMessage.new(
  id: "dev_1",
  content: "You are a helpful assistant."
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | yes | Unique message identifier |
| `content` | `String` | yes | Text content |
| `name` | `String\|nil` | no | Optional sender name |
| `role` | `String` | auto | Always `"developer"` |

### SystemMessage

Global instructions that apply to all interactions.

```ruby
AgUiProtocol::Core::Types::SystemMessage.new(
  id: "sys_1",
  content: "Follow the AG-UI protocol."
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | yes | Unique message identifier |
| `content` | `String` | yes | Text content |
| `name` | `String\|nil` | no | Optional sender name |
| `role` | `String` | auto | Always `"system"` |

### ToolMessage

The result of a tool execution.

```ruby
AgUiProtocol::Core::Types::ToolMessage.new(
  id: "tool_msg_1",
  tool_call_id: "tc_1",
  content: "Found 42 results"
)

# On error
AgUiProtocol::Core::Types::ToolMessage.new(
  id: "tool_msg_2",
  tool_call_id: "tc_2",
  content: nil,
  error: "Connection timeout"
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | yes | Unique message identifier |
| `tool_call_id` | `String` | yes | ID of the tool call this responds to |
| `content` | `String\|nil` | no | Tool output or nil if error |
| `error` | `String\|nil` | no | Error message if tool failed |
| `role` | `String` | auto | Always `"tool"` |

### ActivityMessage

Structured progress updates that display between chat messages.

```ruby
AgUiProtocol::Core::Types::ActivityMessage.new(
  id: "activity_1",
  activity_type: "SEARCH",
  content: { "query" => "...", "results_count" => 42 }
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | yes | Unique message identifier |
| `activity_type` | `String` | yes | Discriminator for renderer selection |
| `content` | `Hash` | yes | Structured payload |
| `role` | `String` | auto | Always `"activity"` |

### ReasoningMessage

Represents a reasoning message from an agent with chain-of-thought content.

```ruby
AgUiProtocol::Core::Types::ReasoningMessage.new(
  id: "reason_1",
  content: "Let me think through this step by step..."
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | yes | Unique message identifier |
| `content` | `String` | yes | Reasoning content (plaintext when not encrypted) |
| `encrypted_value` | `String|nil` | no | Encrypted reasoning content in zero-data-retention mode |
| `role` | `String` | auto | Always `"reasoning"` |

### Interrupt

Represents an interrupt that occurred during agent execution for human-in-the-loop workflows.

```ruby
AgUiProtocol::Core::Types::Interrupt.new(
  id: "int_1",
  reason: "input_required",
  message: "Please provide additional information"
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | yes | Unique identifier |
| `reason` | `String` | yes | Reason for the interrupt |
| `message` | `String|nil` | no | Human-readable message |
| `tool_call_id` | `String|nil` | no | Associated tool call if applicable |
| `response_schema` | `Object|nil` | no | JSON schema for response |
| `expires_at` | `String|nil` | no | ISO timestamp when interrupt expires |
| `metadata` | `Object|nil` | no | Arbitrary metadata |

### ResumeEntry

Represents an entry for resuming an interrupted run.

```ruby
AgUiProtocol::Core::Types::ResumeEntry.new(
  interrupt_id: "int_1",
  status: "resolved",
  payload: { "answer" => "42" }
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `interrupt_id` | `String` | yes | ID of the interrupt being resolved |
| `status` | `String|nil` | no | Resolution status ("resolved" or "cancelled") |
| `payload` | `Object|nil` | no | Response payload for the interrupt |

See `references/events.md` for `RunFinishedInterruptOutcome` — the outcome type used in `RunFinishedEvent.outcome:` to signal an interrupted run.

---

## Content Types

### TextInputContent

A text fragment in a multimodal message.

```ruby
AgUiProtocol::Core::Types::TextInputContent.new(
  text: "Hello!",
  type: "text"
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `text` | `String` | yes | Text content |
| `type` | `String` | no | Fragment type, defaults to `"text"` |

### BinaryInputContent

Binary data - images, audio, files.

```ruby
# By URL
AgUiProtocol::Core::Types::BinaryInputContent.new(
  mime_type: "image/png",
  url: "https://example.com/image.png"
)

# By base64 data
AgUiProtocol::Core::Types::BinaryInputContent.new(
  mime_type: "image/png",
  data: "iVBORw0KGgoAAAANSUhEUgAAAAE..."
)

# By content ID
AgUiProtocol::Core::Types::BinaryInputContent.new(
  mime_type: "image/png",
  id: "uploaded_image_123"
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `mime_type` | `String` | yes | MIME type (e.g., `"image/png"`) |
| `type` | `String` | no | Fragment type, defaults to `"binary"` |
| `id` | `String|nil` | no | Reference to uploaded content |
| `url` | `String|nil` | no | Remote URL |
| `data` | `String|nil` | no | Base64 encoded content |
| `filename` | `String|nil` | no | Optional filename hint |

**Raises** `ArgumentError` if none of `id`, `url`, or `data` is provided.

### ImageInputContent

An image content fragment in a multimodal message.

```ruby
AgUiProtocol::Core::Types::ImageInputContent.new(
  source: {
    type: "url",
    value: "https://example.com/photo.png",
    mime_type: "image/png"
  }
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `source` | `InputContentDataSource\|InputContentUrlSource\|Hash` | yes | Content source |
| `metadata` | `Object\|nil` | no | Optional metadata |
| `type` | `String` | no | Fragment type, defaults to `"image"` |

### AudioInputContent

An audio content fragment in a multimodal message.

```ruby
AgUiProtocol::Core::Types::AudioInputContent.new(
  source: {
    type: "url",
    value: "https://example.com/audio.mp3",
    mime_type: "audio/mp3"
  }
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `source` | `InputContentDataSource\|InputContentUrlSource\|Hash` | yes | Content source |
| `metadata` | `Object\|nil` | no | Optional metadata |
| `type` | `String` | no | Fragment type, defaults to `"audio"` |

### VideoInputContent

A video content fragment in a multimodal message.

```ruby
AgUiProtocol::Core::Types::VideoInputContent.new(
  source: {
    type: "url",
    value: "https://example.com/video.mp4",
    mime_type: "video/mp4"
  }
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `source` | `InputContentDataSource\|InputContentUrlSource\|Hash` | yes | Content source |
| `metadata` | `Object\|nil` | no | Optional metadata |
| `type` | `String` | no | Fragment type, defaults to `"video"` |

### DocumentInputContent

A document content fragment in a multimodal message.

```ruby
AgUiProtocol::Core::Types::DocumentInputContent.new(
  source: {
    type: "url",
    value: "https://example.com/doc.pdf",
    mime_type: "application/pdf"
  }
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `source` | `InputContentDataSource\|InputContentUrlSource\|Hash` | yes | Content source |
| `metadata` | `Object\|nil` | no | Optional metadata |
| `type` | `String` | no | Fragment type, defaults to `"document"` |

### InputContentDataSource

A data source for multimodal input content using base64-encoded data.

```ruby
AgUiProtocol::Core::Types::InputContentDataSource.new(
  value: "base64encoded...",
  mime_type: "image/png"
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `value` | `String` | yes | Base64 encoded content |
| `mime_type` | `String` | yes | MIME type of the content |
| `type` | `String` | no | Source type, defaults to `"data"` |

### InputContentUrlSource

A URL source for multimodal input content.

```ruby
AgUiProtocol::Core::Types::InputContentUrlSource.new(
  value: "https://example.com/image.png",
  mime_type: "image/png"
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `value` | `String` | yes | URL string |
| `mime_type` | `String|nil` | no | Optional MIME type |
| `type` | `String` | no | Source type, defaults to `"url"` |

---

## Tool Types

### FunctionCall

A function invocation inside a tool call. Contains name and JSON-encoded arguments.

```ruby
AgUiProtocol::Core::Types::FunctionCall.new(
  name: "web_search",
  arguments: '{"q":"AG-UI protocol","limit":10}'
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `name` | `String` | yes | Function name |
| `arguments` | `String` | yes | JSON-encoded arguments |

### ToolCall

A tool call embedded in an assistant message.

```ruby
# From FunctionCall object
tc = AgUiProtocol::Core::Types::ToolCall.new(
  id: "tc_1",
  function: AgUiProtocol::Core::Types::FunctionCall.new(
    name: "web_search",
    arguments: '{"q":"..."}'
  )
)

# From hash (more common)
tc = AgUiProtocol::Core::Types::ToolCall.new(
  id: "tc_1",
  function: { name: "web_search", arguments: '{"q":"..."}' }
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `id` | `String` | yes | Unique tool call identifier |
| `function` | `FunctionCall\|Hash` | yes | Function name and arguments |
| `type` | `String` | no | Type, defaults to `"function"` |

### Tool

A tool definition - describes what tools are available to the agent.

```ruby
AgUiProtocol::Core::Types::Tool.new(
  name: "web_search",
  description: "Search the web for information",
  parameters: {
    "type" => "object",
    "properties" => {
      "q" => { "type" => "string", "description" => "The search query" }
    },
    "required" => ["q"]
  }
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `name` | `String` | yes | Tool name |
| `description` | `String` | yes | What the tool does |
| `parameters` | `Object` | yes | JSON Schema for tool parameters |

---

## Input Types

### Context

A piece of contextual information provided to the agent.

```ruby
AgUiProtocol::Core::Types::Context.new(
  description: "User locale",
  value: "en-US"
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `description` | `String` | yes | What this context represents |
| `value` | `String` | yes | The actual context value |

### RunAgentInput

The complete input payload for starting an agent run.

```ruby
input = AgUiProtocol::Core::Types::RunAgentInput.new(
  thread_id: "thread_123",
  run_id: "run_456",
  state: {},
  messages: [msg1, msg2],
  tools: [web_search_tool],
  context: [locale_ctx],
  forwarded_props: {}
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `thread_id` | `String` | yes | Conversation thread ID |
| `run_id` | `String` | yes | Unique run ID |
| `state` | `Object` | yes | Agent's current state |
| `messages` | `Array<BaseMessage>` | yes | Conversation history |
| `tools` | `Array<Tool>` | yes | Available tools |
| `context` | `Array<Context>` | yes | Context entries |
| `forwarded_props` | `Object` | yes | App-specific data |
| `parent_run_id` | `String\|nil` | no | Lineage pointer for branching |

**Sorbet validation** - The following raise `ArgumentError` if violated:
- `messages` MUST be an `Array<BaseMessage>`
- `tools` MUST be an `Array<Tool>`
- `context` MUST be an `Array<Context>`

---

## Roles

All message types have a `role` property. Valid roles:

```ruby
AgUiProtocol::Core::Types::Role
# => ["developer", "system", "assistant", "user", "tool", "activity", "reasoning"]
```

| Role | Class |
|---|---|
| `"developer"` | DeveloperMessage |
| `"system"` | SystemMessage |
| `"assistant"` | AssistantMessage |
| `"user"` | UserMessage |
| `"tool"` | ToolMessage |
| `"activity"` | ActivityMessage |
| `"reasoning"` | ReasoningMessage |

The role property is automatically set by each class constructor.

---

## Serialization

All types serialize to JSON with camelCase keys:

```ruby
msg = UserMessage.new(id: "1", content: "Hi")
msg.to_h
# => { id: "1", role: "user", content: "Hi", name: nil }

msg.as_json
# => { "id" => "1", "role" => "user", "content" => "Hi", "name" => nil }

msg.to_json
# => "{\"id\":\"1\",\"role\":\"user\",\"content\":\"Hi\",\"name\":null}"
```

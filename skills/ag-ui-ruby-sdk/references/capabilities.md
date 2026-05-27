# Agent Capabilities

Agent capabilities define what an agent can do. They are declared by the agent implementation and communicated to the client during a run.

## AgentCapabilities

`AgUiProtocol::Core::Capabilities::AgentCapabilities`

A categorized snapshot of an agent's current capabilities. All fields are optional.

```ruby
caps = AgUiProtocol::Core::Capabilities::AgentCapabilities.new(
  identity: IdentityCapabilities.new(name: "My Agent"),
  transport: TransportCapabilities.new(streaming: true),
  tools: ToolsCapabilities.new(supported: true),
  output: OutputCapabilities.new(structured_output: true),
  state: StateCapabilities.new(snapshots: true, deltas: true),
  reasoning: ReasoningCapabilities.new(supported: true, streaming: true),
  multimodal: MultimodalCapabilities.new(
    input: MultimodalInputCapabilities.new(image: true, audio: true),
    output: MultimodalOutputCapabilities.new(image: true)
  ),
  human_in_the_loop: HumanInTheLoopCapabilities.new(interrupts: true)
)
```

## IdentityCapabilities

Basic metadata about the agent for discovery UIs and marketplaces.

```ruby
AgUiProtocol::Core::Capabilities::IdentityCapabilities.new(
  name: "My Agent",
  type: "langgraph",
  description: "A helpful assistant",
  version: "1.0.0",
  provider: "My Company",
  documentation_url: "https://docs.example.com"
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `name` | `String\|nil` | no | Human-readable name |
| `type` | `String\|nil` | no | Framework (e.g., "langgraph", "mastra", "crewai") |
| `description` | `String\|nil` | no | What the agent does |
| `version` | `String\|nil` | no | Semantic version |
| `provider` | `String\|nil` | no | Organization or team |
| `documentation_url` | `String\|nil` | no | Documentation URL |
| `metadata` | `Hash\|nil` | no | Integration-specific key-value pairs |

## TransportCapabilities

Declares which transport mechanisms the agent supports.

```ruby
AgUiProtocol::Core::Capabilities::TransportCapabilities.new(
  streaming: true,
  websocket: false,
  http_binary: false,
  push_notifications: false,
  resumable: true
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `streaming` | `Boolean\|nil` | no | `true` if streams via SSE |
| `websocket` | `Boolean\|nil` | no | `true` if accepts WebSocket |
| `http_binary` | `Boolean\|nil` | no | `true` if supports protobuf over HTTP |
| `push_notifications` | `Boolean\|nil` | no | `true` if sends async updates via webhooks |
| `resumable` | `Boolean\|nil` | no | `true` if supports resuming interrupted streams |

## ToolsCapabilities

Tool calling capabilities.

```ruby
AgUiProtocol::Core::Capabilities::ToolsCapabilities.new(
  supported: true,
  items: [tool1, tool2],
  parallel_calls: true,
  client_provided: true
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `supported` | `Boolean\|nil` | no | `true` if can make tool calls |
| `items` | `Array<Tool>\|nil` | no | Tools this agent provides |
| `parallel_calls` | `Boolean\|nil` | no | `true` if can invoke multiple tools concurrently |
| `client_provided` | `Boolean\|nil` | no | `true` if accepts runtime tools from client |

## OutputCapabilities

Output format support.

```ruby
AgUiProtocol::Core::Capabilities::OutputCapabilities.new(
  structured_output: true,
  supported_mime_types: ["text/plain", "application/json"]
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `structured_output` | `Boolean\|nil` | no | `true` if can produce JSON matching a schema |
| `supported_mime_types` | `Array<String>\|nil` | no | MIME types the agent can produce |

## StateCapabilities

State and memory management capabilities.

```ruby
AgUiProtocol::Core::Capabilities::StateCapabilities.new(
  snapshots: true,
  deltas: true,
  memory: false,
  persistent_state: true
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `snapshots` | `Boolean\|nil` | no | `true` if emits STATE_SNAPSHOT events |
| `deltas` | `Boolean\|nil` | no | `true` if emits STATE_DELTA events |
| `memory` | `Boolean\|nil` | no | `true` if has long-term memory beyond current thread |
| `persistent_state` | `Boolean\|nil` | no | `true` if state persists across runs in same thread |

## MultiAgentCapabilities

Multi-agent coordination capabilities.

```ruby
AgUiProtocol::Core::Capabilities::MultiAgentCapabilities.new(
  supported: true,
  delegation: true,
  handoffs: false,
  sub_agents: [SubAgentInfo.new(name: "search", description: "Web search")]
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `supported` | `Boolean\|nil` | no | `true` if participates in multi-agent coordination |
| `delegation` | `Boolean\|nil` | no | `true` if can delegate subtasks |
| `handoffs` | `Boolean\|nil` | no | `true` if can transfer conversation to another agent |
| `sub_agents` | `Array<SubAgentInfo>\|nil` | no | List of sub-agents this agent can invoke |

### SubAgentInfo

```ruby
AgUiProtocol::Core::Capabilities::SubAgentInfo.new(
  name: "search",
  description: "Web search sub-agent"
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `name` | `String` | yes | Unique name or identifier |
| `description` | `String\|nil` | no | What this sub-agent specializes in |

## ReasoningCapabilities

Reasoning and thinking capabilities.

```ruby
AgUiProtocol::Core::Capabilities::ReasoningCapabilities.new(
  supported: true,
  streaming: true,
  encrypted: false
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `supported` | `Boolean\|nil` | no | `true` if produces reasoning/thinking tokens |
| `streaming` | `Boolean\|nil` | no | `true` if tokens are streamed incrementally |
| `encrypted` | `Boolean\|nil` | no | `true` if reasoning content is encrypted (ZDR mode) |

## MultimodalCapabilities

Multimodal input and output support.

```ruby
AgUiProtocol::Core::Capabilities::MultimodalCapabilities.new(
  input: MultimodalInputCapabilities.new(image: true, audio: true),
  output: MultimodalOutputCapabilities.new(image: false, audio: true)
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `input` | `MultimodalInputCapabilities\|nil` | no | Modalities agent can accept |
| `output` | `MultimodalOutputCapabilities\|nil` | no | Modalities agent can produce |

### MultimodalInputCapabilities

```ruby
AgUiProtocol::Core::Capabilities::MultimodalInputCapabilities.new(
  image: true,
  audio: true,
  video: false,
  pdf: true,
  file: true
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `image` | `Boolean\|nil` | no | `true` if can process images |
| `audio` | `Boolean\|nil` | no | `true` if can process audio |
| `video` | `Boolean\|nil` | no | `true` if can process video |
| `pdf` | `Boolean\|nil` | no | `true` if can process PDFs |
| `file` | `Boolean\|nil` | no | `true` if can process arbitrary files |

### MultimodalOutputCapabilities

```ruby
AgUiProtocol::Core::Capabilities::MultimodalOutputCapabilities.new(
  image: true,
  audio: false
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `image` | `Boolean\|nil` | no | `true` if can generate images |
| `audio` | `Boolean\|nil` | no | `true` if can produce audio output |

## ExecutionCapabilities

Execution control and limits.

```ruby
AgUiProtocol::Core::Capabilities::ExecutionCapabilities.new(
  code_execution: true,
  sandboxed: true,
  max_iterations: 100,
  max_execution_time: 60000
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `code_execution` | `Boolean\|nil` | no | `true` if can execute code |
| `sandboxed` | `Boolean\|nil` | no | `true` if code runs in sandbox |
| `max_iterations` | `Integer\|nil` | no | Max tool-call/reasoning iterations per run |
| `max_execution_time` | `Integer\|nil` | no | Max wall-clock time in milliseconds |

## HumanInTheLoopCapabilities

Human-in-the-loop interaction support.

```ruby
AgUiProtocol::Core::Capabilities::HumanInTheLoopCapabilities.new(
  supported: true,
  approvals: true,
  interventions: true,
  feedback: true,
  interrupts: true,
  approve_with_edits: true
)
```

| Property | Type | Required | Description |
|---|---|---|---|
| `supported` | `Boolean\|nil` | no | `true` if supports any form of HITL |
| `approvals` | `Boolean\|nil` | no | `true` if can pause for explicit approval |
| `interventions` | `Boolean\|nil` | no | `true` if allows mid-execution intervention |
| `feedback` | `Boolean\|nil` | no | `true` if can incorporate user feedback |
| `interrupts` | `Boolean\|nil` | no | `true` if participates in interrupt protocol |
| `approve_with_edits` | `Boolean\|nil` | no | `true` if tool-call interrupts accept editedArgs |
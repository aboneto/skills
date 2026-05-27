require "ag_ui_protocol/core/capabilities"

identity = AgUiProtocol::Core::Capabilities::IdentityCapabilities.new(
  name: "My Agent",
  type: "langgraph",
  description: "A helpful assistant",
  version: "1.0.0",
  provider: "My Company",
  documentation_url: "https://docs.example.com"
)

transport = AgUiProtocol::Core::Capabilities::TransportCapabilities.new(
  streaming: true,
  websocket: false,
  http_binary: false,
  push_notifications: false,
  resumable: true
)

tools = AgUiProtocol::Core::Capabilities::ToolsCapabilities.new(
  supported: true,
  parallel_calls: true,
  client_provided: true
)

state = AgUiProtocol::Core::Capabilities::StateCapabilities.new(
  snapshots: true,
  deltas: true,
  memory: false,
  persistent_state: true
)

reasoning = AgUiProtocol::Core::Capabilities::ReasoningCapabilities.new(
  supported: true,
  streaming: true,
  encrypted: false
)

multimodal = AgUiProtocol::Core::Capabilities::MultimodalCapabilities.new(
  input: AgUiProtocol::Core::Capabilities::MultimodalInputCapabilities.new(
    image: true,
    audio: true,
    video: false,
    pdf: true,
    file: true
  ),
  output: AgUiProtocol::Core::Capabilities::MultimodalOutputCapabilities.new(
    image: true,
    audio: false
  )
)

human_in_the_loop = AgUiProtocol::Core::Capabilities::HumanInTheLoopCapabilities.new(
  supported: true,
  approvals: true,
  interventions: true,
  feedback: true,
  interrupts: true,
  approve_with_edits: true
)

caps = AgUiProtocol::Core::Capabilities::AgentCapabilities.new(
  identity: identity,
  transport: transport,
  tools: tools,
  output: AgUiProtocol::Core::Capabilities::OutputCapabilities.new(
    structured_output: true,
    supported_mime_types: ["text/plain", "application/json"]
  ),
  state: state,
  reasoning: reasoning,
  multimodal: multimodal,
  human_in_the_loop: human_in_the_loop
)

puts caps

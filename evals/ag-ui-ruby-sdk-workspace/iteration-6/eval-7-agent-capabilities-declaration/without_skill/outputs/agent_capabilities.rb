require "json"

AgentCapabilities = Struct.new(
  :identity,
  :transport,
  :tools,
  :state,
  :reasoning,
  :multimodal,
  :human_in_the_loop,
  keyword_init: true
)

capabilities = AgentCapabilities.new(
  identity: {
    name: "skill-agent",
    version: "0.1.0"
  },
  transport: {
    type: "stdio",
    config: { encoding: "json-rpc" }
  },
  tools: {
    enabled: true,
    registry: %w[read write edit bash search],
    max_concurrent: 5,
    timeout_ms: 120_000
  },
  state: {
    persistent: false,
    scope: "session",
    storage: "memory"
  },
  reasoning: {
    enabled: true,
    mode: "chain_of_thought",
    max_tokens: 4096
  },
  multimodal: {
    input: %w[text code],
    output: %w[text code markup]
  },
  human_in_the_loop: {
    enabled: true,
    approval_required_for: %w[write destructive_commands],
    escalation_contact: nil
  }
)

puts JSON.pretty_generate(capabilities.to_h)

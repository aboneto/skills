require "ag_ui_protocol"

interrupt = AgUiProtocol::Core::Types::Interrupt.new(
  id: "int_approval_1",
  reason: "input_required",
  message: "Please approve the fund transfer of $5,000 to account #12345",
  tool_call_id: "tc_transfer_1",
  response_schema: {
    "type" => "object",
    "properties" => {
      "approved" => { "type" => "boolean", "description" => "Whether to approve the transfer" },
      "note"     => { "type" => "string",  "description" => "Optional note for the transaction" }
    },
    "required" => ["approved"]
  },
  expires_at: (Time.now + 3600).iso8601,
  metadata: { "step" => "approval", "amount_cents" => 500_000 }
)

outcome = AgUiProtocol::Core::Events::RunFinishedInterruptOutcome.new(
  interrupts: [interrupt]
)

resume = AgUiProtocol::Core::Types::ResumeEntry.new(
  interrupt_id: "int_approval_1",
  status: "resolved",
  payload: { "approved" => true, "note" => "Looks good, proceed" }
)

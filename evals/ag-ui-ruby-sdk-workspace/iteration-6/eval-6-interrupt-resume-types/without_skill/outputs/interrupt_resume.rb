require "json"

Interrupt = Data.define(:id, :type, :message, :payload, :created_at) do
  def initialize(id:, type:, message:, payload: {}, created_at: Time.now)
    super
  end

  def to_h
    { id:, type:, message:, payload:, created_at: created_at.iso8601 }
  end
end

ResumeEntry = Data.define(:interrupt_id, :action, :payload, :resolved_at, :metadata) do
  def initialize(interrupt_id:, action: "continue", payload: {}, resolved_at: Time.now, metadata: {})
    super
  end

  def approved?
    action == "approve"
  end

  def to_h
    {
      interrupt_id:,
      action:,
      payload:,
      resolved_at: resolved_at.iso8601,
      metadata:
    }
  end
end

approval_interrupt = Interrupt.new(
  id: "int-001",
  type: "human_approval",
  message: "Review the generated SQL query before execution",
  payload: { sql: "DELETE FROM users WHERE deleted_at IS NULL" }
)

puts "=== Interrupt raised ==="
puts JSON.pretty_generate(approval_interrupt.to_h)

resume = ResumeEntry.new(
  interrupt_id: approval_interrupt.id,
  action: "approve",
  payload: {
    sql: "UPDATE users SET deleted_at = NOW() WHERE deleted_at IS NULL",
    reviewer: "antonio",
    note: "Soft-delete is safer; adjusted query accordingly."
  },
  metadata: { reviewed_at: Time.now.iso8601 }
)

puts "\n=== Resume entry created ==="
puts JSON.pretty_generate(resume.to_h)

if resume.approved?
  puts "\n=> Approved. Executing SQL: #{resume.payload[:sql]}"
else
  puts "\n=> Rejected. Workflow halted."
end

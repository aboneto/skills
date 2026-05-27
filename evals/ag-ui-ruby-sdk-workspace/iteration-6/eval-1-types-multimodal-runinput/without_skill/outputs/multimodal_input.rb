require "base64"

image_path = "example.png"
image_data = File.binread(image_path)
encoded_image = Base64.strict_encode64(image_data)

content = [
  { type: "text", text: "Here is the image you requested:" },
  { type: "image", source: { type: "base64", media_type: "image/png", data: encoded_image } }
]

message = { role: "user", content: content }

input = {
  thread_id: "thread_abc123",
  run_id: "run_xyz789",
  state: "active",
  messages: [message],
  tools: [
    { type: "function", name: "analyze_image", description: "Analyze image contents" }
  ],
  context: { user_id: "usr_42", session: "default" },
  forwarded_props: { source: "mobile_app", priority: "normal" }
}

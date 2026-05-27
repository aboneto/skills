```ruby
#!/usr/bin/env ruby
require 'ag-ui'

# Configure the AG-UI client using environment variables
client = AGUI::Client.new(
  api_key: ENV.fetch('AGUI_API_KEY', 'default-api-key'),
  base_url: ENV.fetch('AGUI_BASE_URL', 'https://api.ag-ui.com')
)

# Start a new run
run = client.start_run(
  name: 'baseline-run',
  metadata: { source: 'evaluation' }
)

begin
  # Stream a text message containing 'Hello, World!'
  run.stream_message(
    role: 'assistant',
    content: 'Hello, World!'
  )

  # Finish the run successfully
  run.finish(status: 'success')

  puts "Run finished successfully. Run ID: #{run.id}"
rescue AGUI::Error => e
  # Mark the run as failed if something goes wrong
  run.finish(status: 'error') if run&.active?
  abort "Run failed: #{e.message}"
end
```

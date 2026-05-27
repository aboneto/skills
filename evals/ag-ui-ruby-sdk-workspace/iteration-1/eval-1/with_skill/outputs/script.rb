# frozen_string_literal: true

require 'securerandom'
require 'json'
require 'base64'

begin
  require 'ag_ui_protocol'
rescue LoadError
  # Intentar cargar desde rutas locales comunes del workspace
  possible_paths = [
    '/Users/antonioneto/Documents/workspace/ag-ui/sdks/community/ruby/lib',
    File.expand_path('../ag-ui/sdks/community/ruby/lib', __dir__)
  ]
  possible_paths.each do |path|
    if Dir.exist?(path)
      $LOAD_PATH.unshift(path)
      begin
        require 'ag_ui_protocol'
        break
      rescue LoadError
        # Continuar buscando
      end
    end
  end
end

# 1. Crear TextInputContent
text_content = AgUiProtocol::Core::Types::TextInputContent.new(
  text: "Describe the contents of this image and suggest changes."
)

# 2. Crear BinaryInputContent con datos representados en base64 (ejemplo de un pixel PNG)
mock_image_base64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
binary_content = AgUiProtocol::Core::Types::BinaryInputContent.new(
  mime_type: "image/png",
  data: mock_image_base64
)

# 3. Crear el UserMessage multimodal que contiene TextInputContent y BinaryInputContent
user_message = AgUiProtocol::Core::Types::UserMessage.new(
  id: "msg_user_#{SecureRandom.uuid}",
  content: [text_content, binary_content]
)

# 4. Definir otros mensajes opcionales en el historial (ej. SystemMessage)
system_message = AgUiProtocol::Core::Types::SystemMessage.new(
  id: "msg_system_#{SecureRandom.uuid}",
  content: "You are a helpful assistant specialized in image analysis."
)

messages = [system_message, user_message]

# 5. Definir las herramientas (Tools) disponibles para el agente
analyzer_tool = AgUiProtocol::Core::Types::Tool.new(
  name: "image_analyzer",
  description: "Analyzes image characteristics and colors",
  parameters: {
    type: "object",
    properties: {
      detailed: { type: "boolean", description: "Whether to return a detailed report" }
    },
    required: ["detailed"]
  }
)

tools = [analyzer_tool]

# 6. Definir el contexto (Context)
locale_context = AgUiProtocol::Core::Types::Context.new(
  description: "locale",
  value: "es-ES"
)

context = [locale_context]

# 7. Construir el objeto RunAgentInput completo
run_agent_input = AgUiProtocol::Core::Types::RunAgentInput.new(
  thread_id: "thread_#{SecureRandom.uuid}",
  run_id: "run_#{SecureRandom.uuid}",
  state: { "current_step" => "init" },
  messages: messages,
  tools: tools,
  context: context,
  forwarded_props: { "client_version" => "1.0.0" }
)

# 8. Mostrar la serialización JSON del objeto construido
puts "--- RunAgentInput JSON ---"
puts JSON.pretty_generate(JSON.parse(run_agent_input.to_json))

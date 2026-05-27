require_relative "path/to/ag_ui_protocol/core/types"

url_src_image = AgUiProtocol::Core::Types::InputContentUrlSource.new(
  value: "https://example.com/photo.png",
  mime_type: "image/png"
)

image = AgUiProtocol::Core::Types::ImageInputContent.new(
  source: url_src_image
)

url_src_audio = AgUiProtocol::Core::Types::InputContentUrlSource.new(
  value: "https://example.com/audio.mp3",
  mime_type: "audio/mp3"
)

audio = AgUiProtocol::Core::Types::AudioInputContent.new(
  source: url_src_audio
)

url_src_video = AgUiProtocol::Core::Types::InputContentUrlSource.new(
  value: "https://example.com/video.mp4",
  mime_type: "video/mp4"
)

video = AgUiProtocol::Core::Types::VideoInputContent.new(
  source: url_src_video
)

url_src_doc = AgUiProtocol::Core::Types::InputContentUrlSource.new(
  value: "https://example.com/doc.pdf",
  mime_type: "application/pdf"
)

document = AgUiProtocol::Core::Types::DocumentInputContent.new(
  source: url_src_doc
)

data_src = AgUiProtocol::Core::Types::InputContentDataSource.new(
  value: "iVBORw0KGgoAAAANSUhEUgAAAAE...",
  mime_type: "image/png"
)

image_data = AgUiProtocol::Core::Types::ImageInputContent.new(
  source: data_src
)

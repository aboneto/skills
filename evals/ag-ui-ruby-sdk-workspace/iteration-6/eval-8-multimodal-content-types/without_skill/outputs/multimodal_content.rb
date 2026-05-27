require "base64"
require "json"
require "open-uri"
require "net/http"

module MultimodalContent
  class Content
    attr_reader :type, :source, :mime_type

    def initialize(type:, source:, mime_type:)
      @type = type
      @source = source
      @mime_type = mime_type
    end

    def to_h
      { type: @type, source: @source, mime_type: @mime_type }
    end
  end

  class UrlContent < Content
    def initialize(type:, url:, mime_type:)
      super(type: type, source: { url: url }, mime_type: mime_type)
      @url = url
    end

    def fetch
      URI.parse(@url).open(&:read)
    end
  end

  class Base64Content < Content
    def initialize(type:, data:, mime_type:)
      encoded = Base64.strict_encode64(data)
      super(type: type, source: { base64: encoded }, mime_type: mime_type)
      @raw = data
    end

    def decode
      Base64.decode64(@source[:base64])
    end
  end

  class Image < UrlContent
    MIME_TYPES = %w[image/jpeg image/png image/gif image/webp image/svg+xml].freeze

    def initialize(url:, mime_type: "image/png")
      super(type: :image, url: url, mime_type: mime_type)
    end
  end

  class Audio < UrlContent
    MIME_TYPES = %w[audio/mpeg audio/ogg audio/wav audio/flac audio/aac].freeze

    def initialize(url:, mime_type: "audio/mpeg")
      super(type: :audio, url: url, mime_type: mime_type)
    end
  end

  class Video < UrlContent
    MIME_TYPES = %w[video/mp4 video/webm video/ogg video/quicktime].freeze

    def initialize(url:, mime_type: "video/mp4")
      super(type: :video, url: url, mime_type: mime_type)
    end
  end

  class Document < UrlContent
    MIME_TYPES = %w[application/pdf text/html text/plain application/json].freeze

    def initialize(url:, mime_type: "text/plain")
      super(type: :document, url: url, mime_type: mime_type)
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  image = MultimodalContent::Image.new(url: "https://example.com/photo.png")
  audio = MultimodalContent::Audio.new(url: "https://example.com/sound.mp3")
  video = MultimodalContent::Video.new(url: "https://example.com/clip.mp4")
  document = MultimodalContent::Document.new(url: "https://example.com/report.pdf")

  raw_bytes = "\x89PNG\r\n\x1a\n".b
  base64_img = MultimodalContent::Base64Content.new(
    type: :image,
    data: raw_bytes,
    mime_type: "image/png"
  )

  items = [image, audio, video, document, base64_img]
  items.each { |c| puts JSON.pretty_generate(c.to_h) }
end

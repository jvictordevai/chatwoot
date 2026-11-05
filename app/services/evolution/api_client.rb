# Thin HTTP client for a self-hosted Evolution API v2 (Baileys) server.
# Docs: https://doc.evolution-api.com/v2/api-reference
#
# Configuration (ENV):
#   EVOLUTION_API_URL  - base url, e.g. http://evolution-api.railway.internal:8080
#   EVOLUTION_API_KEY  - global AUTHENTICATION_API_KEY of the Evolution server
class Evolution::ApiClient
  class Error < StandardError
    attr_reader :status, :body

    def initialize(message, status: nil, body: nil)
      super(message)
      @status = status
      @body = body
    end
  end

  class NotConfiguredError < Error; end

  WEBHOOK_EVENTS = %w[QRCODE_UPDATED CONNECTION_UPDATE MESSAGES_UPSERT MESSAGES_UPDATE].freeze
  DEFAULT_TIMEOUT = 15

  def self.configured?
    ENV['EVOLUTION_API_URL'].present? && ENV['EVOLUTION_API_KEY'].present?
  end

  def initialize(base_url: ENV.fetch('EVOLUTION_API_URL', nil), api_key: ENV.fetch('EVOLUTION_API_KEY', nil))
    raise NotConfiguredError, 'Evolution API is not configured (EVOLUTION_API_URL / EVOLUTION_API_KEY)' if base_url.blank? || api_key.blank?

    @base_url = base_url.to_s.chomp('/')
    @api_key = api_key
  end

  def create_instance(instance_name:, webhook_url:)
    request(:post, '/instance/create', {
              instanceName: instance_name,
              integration: 'WHATSAPP-BAILEYS',
              qrcode: true,
              groupsIgnore: true,
              readMessages: false,
              syncFullHistory: false,
              webhook: {
                url: webhook_url,
                enabled: true,
                byEvents: false,
                base64: true,
                events: WEBHOOK_EVENTS
              }
            })
  end

  def set_webhook(instance_name:, webhook_url:)
    request(:post, "/webhook/set/#{escape(instance_name)}", {
              webhook: { url: webhook_url, enabled: true, byEvents: false, base64: true, events: WEBHOOK_EVENTS }
            })
  end

  # Returns { 'base64' => 'data:image/png;base64,...', 'code' => '...', 'pairingCode' => '...' }
  # or { 'instance' => { 'state' => 'open' } } when already connected.
  def connect(instance_name)
    request(:get, "/instance/connect/#{escape(instance_name)}")
  end

  # Returns 'open' | 'connecting' | 'close'
  def connection_state(instance_name)
    request(:get, "/instance/connectionState/#{escape(instance_name)}").dig('instance', 'state')
  end

  def fetch_instance(instance_name)
    Array(request(:get, '/instance/fetchInstances', nil, query: { instanceName: instance_name })).first || {}
  end

  def logout(instance_name)
    request(:delete, "/instance/logout/#{escape(instance_name)}")
  end

  def delete_instance(instance_name)
    request(:delete, "/instance/delete/#{escape(instance_name)}")
  end

  def send_text(instance_name, number:, text:, quoted_id: nil)
    body = { number: number, text: text }
    body[:quoted] = { key: { id: quoted_id } } if quoted_id.present?
    request(:post, "/message/sendText/#{escape(instance_name)}", body)
  end

  # options: mimetype:, caption:, file_name:, quoted_id:
  def send_media(instance_name, number:, mediatype:, media:, **options)
    body = { number: number, mediatype: mediatype, media: media, mimetype: options[:mimetype], caption: options[:caption],
             fileName: options[:file_name] }.compact
    body[:quoted] = { key: { id: options[:quoted_id] } } if options[:quoted_id].present?
    request(:post, "/message/sendMedia/#{escape(instance_name)}", body)
  end

  def send_audio(instance_name, number:, audio:, quoted_id: nil)
    body = { number: number, audio: audio }
    body[:quoted] = { key: { id: quoted_id } } if quoted_id.present?
    request(:post, "/message/sendWhatsAppAudio/#{escape(instance_name)}", body)
  end

  # Returns { 'base64' => '...', 'mimetype' => 'image/jpeg', 'fileName' => '...' }
  def media_base64(instance_name, message_id:)
    request(:post, "/chat/getBase64FromMediaMessage/#{escape(instance_name)}", {
              message: { key: { id: message_id } },
              convertToMp4: false
            })
  end

  private

  def request(method, path, body = nil, query: nil)
    options = { headers: headers, timeout: DEFAULT_TIMEOUT }
    options[:body] = body.to_json if body
    options[:query] = query if query
    response = HTTParty.send(method, "#{@base_url}#{path}", options)
    return response.parsed_response if response.success?

    raise Error.new(error_message(response), status: response.code, body: response.parsed_response)
  rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, SocketError => e
    raise Error, "Evolution API unreachable: #{e.class}"
  end

  def headers
    { 'apikey' => @api_key, 'Content-Type' => 'application/json' }
  end

  def escape(value)
    ERB::Util.url_encode(value.to_s)
  end

  def error_message(response)
    parsed = response.parsed_response
    details = parsed.is_a?(Hash) ? Array(parsed.dig('response', 'message')).flatten.join(', ') : nil
    "Evolution API error #{response.code}#{": #{details}" if details.present?}"
  end
end

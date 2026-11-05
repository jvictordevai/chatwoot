# Processes normalized Evolution payloads (see Evolution::PayloadNormalizer) through the
# shared WhatsApp pipeline; only media download differs (base64 instead of a media URL).
class Evolution::IncomingMessageService < Whatsapp::IncomingMessageBaseService
  def download_attachment_file(attachment_payload)
    base64 = attachment_payload[:base64].presence || fetch_media(attachment_payload)
    return if base64.blank?

    build_io(base64, attachment_payload)
  rescue Evolution::ApiClient::Error, ArgumentError => e
    Rails.logger.error "[EVOLUTION] media download failed inbox_id=#{inbox.id}: #{e.message}"
    nil
  end

  private

  def fetch_media(attachment_payload)
    response = Evolution::ApiClient.new.media_base64(inbox.channel.provider_config['instance_name'], message_id: attachment_payload[:id])
    attachment_payload[:mime_type] ||= response['mimetype']
    attachment_payload[:filename] ||= response['fileName']
    response['base64']
  end

  def build_io(base64, attachment_payload)
    content_type = attachment_payload[:mime_type].presence || 'application/octet-stream'
    filename = attachment_payload[:filename].presence || default_filename(content_type)
    io = StringIO.new(Base64.decode64(base64.to_s.sub(/\Adata:[^;]+;base64,/, '')))
    io.define_singleton_method(:original_filename) { filename }
    io.define_singleton_method(:content_type) { content_type }
    io
  end

  def default_filename(content_type)
    extension = Rack::Mime::MIME_TYPES.invert[content_type.split(';').first] || '.bin'
    "#{message_type}-#{SecureRandom.hex(4)}#{extension}"
  end
end

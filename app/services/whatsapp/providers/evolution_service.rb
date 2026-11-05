# WhatsApp provider backed by a self-hosted Evolution API (Baileys / QR code login).
# Unofficial WhatsApp Web session: no templates, no 24h window, no Meta webhooks.
class Whatsapp::Providers::EvolutionService < Whatsapp::Providers::BaseService
  MEDIA_TYPES = %w[image video].freeze

  def send_message(phone_number, message)
    @message = message
    response = if message.attachments.present?
                 send_attachment_message(phone_number, message)
               else
                 client.send_text(instance_name, number: phone_number, text: message.outgoing_content.to_s, quoted_id: quoted_id(message))
               end
    response.dig('key', 'id')
  rescue Evolution::ApiClient::Error => e
    mark_failed(message, e.message)
    nil
  end

  def send_template(_phone_number, _template_info, message)
    mark_failed(message, I18n.t('errors.whatsapp.evolution_templates_not_supported', default: 'Templates are not supported on WhatsApp QR inboxes'))
    nil
  end

  def sync_templates
    # Evolution (WhatsApp Web) has no Meta-approved templates.
    whatsapp_channel.mark_message_templates_updated
  end

  def validate_provider_config?
    whatsapp_channel.provider_config['instance_name'].present?
  end

  def api_headers
    {}
  end

  def media_url(_media_id)
    nil
  end

  private

  def client
    @client ||= Evolution::ApiClient.new
  end

  def instance_name
    whatsapp_channel.provider_config['instance_name']
  end

  def quoted_id(message)
    (message.content_attributes || {}).to_h.with_indifferent_access[:in_reply_to_external_id].presence
  end

  def send_attachment_message(phone_number, message)
    attachment = message.attachments.first
    url = attachment.download_url
    return client.send_audio(instance_name, number: phone_number, audio: url, quoted_id: quoted_id(message)) if attachment.file_type == 'audio'

    client.send_media(
      instance_name,
      number: phone_number,
      mediatype: MEDIA_TYPES.include?(attachment.file_type) ? attachment.file_type : 'document',
      media: url,
      mimetype: attachment.file.content_type,
      caption: message.outgoing_content.presence,
      file_name: attachment.file.filename.to_s,
      quoted_id: quoted_id(message)
    )
  end

  def mark_failed(message, error)
    Rails.logger.error "[EVOLUTION] send failed channel_id=#{whatsapp_channel.id}: #{error}"
    return if message.blank?

    message.update!(status: :failed, external_error: error)
  end
end

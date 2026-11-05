# Converts Evolution API webhook payloads (Baileys format) into the Meta/360dialog
# webhook shape consumed by Whatsapp::IncomingMessageBaseService, so contact,
# conversation and attachment handling is shared with the official providers.
#
# messages.upsert  -> { contacts: [...], messages: [...] }      (incoming)
#                  -> { message_echoes: [...] }                  (fromMe = sent from the phone)
# messages.update  -> { statuses: [...] }
class Evolution::PayloadNormalizer
  IGNORED_JID_SUFFIXES = %w[@g.us @broadcast @newsletter].freeze

  TYPE_MAP = {
    'conversation' => 'text',
    'extendedTextMessage' => 'text',
    'imageMessage' => 'image',
    'videoMessage' => 'video',
    'audioMessage' => 'audio',
    'documentMessage' => 'document',
    'documentWithCaptionMessage' => 'document',
    'stickerMessage' => 'sticker',
    'locationMessage' => 'location',
    'contactMessage' => 'text',
    'reactionMessage' => 'reaction',
    'protocolMessage' => 'ephemeral'
  }.freeze

  STATUS_MAP = {
    'SERVER_ACK' => 'sent',
    'DELIVERY_ACK' => 'delivered',
    'READ' => 'read',
    'PLAYED' => 'read',
    'ERROR' => 'failed'
  }.freeze

  attr_reader :business_number

  def initialize(payload, business_number: nil)
    @payload = payload.with_indifferent_access
    @data = @payload[:data] || {}
    @business_number = business_number.to_s.delete('+')
  end

  def event
    @payload[:event].to_s.downcase.tr('_', '.')
  end

  def outgoing_echo?
    @data.dig(:key, :fromMe) == true
  end

  # Contact phone digits (no '+'), resolving WhatsApp LIDs to the real phone when Evolution provides it.
  def contact_number
    jid = [@data.dig(:key, :remoteJid), @data.dig(:key, :remoteJidAlt), @data.dig(:key, :senderPn)]
          .compact.find { |candidate| candidate.to_s.end_with?('@s.whatsapp.net') }
    jid.to_s.split('@').first.to_s.split(':').first.presence
  end

  def ignorable?
    remote_jid = @data.dig(:key, :remoteJid).to_s
    return true if remote_jid.blank? || IGNORED_JID_SUFFIXES.any? { |suffix| remote_jid.end_with?(suffix) }

    contact_number.blank?
  end

  def message_params
    return if ignorable?

    message = build_message
    if outgoing_echo?
      { message_echoes: [message.merge(from: business_number, to: contact_number)] }
    else
      {
        contacts: [{ profile: { name: @data[:pushName].presence || contact_number }, wa_id: contact_number }],
        messages: [message.merge(from: contact_number)]
      }
    end.with_indifferent_access
  end

  def status_params
    message_id = @data[:keyId] || @data[:messageId] || @data.dig(:key, :id)
    status = STATUS_MAP[@data[:status].to_s.upcase]
    return if message_id.blank? || status.blank?

    { statuses: [{ id: message_id, status: status }] }.with_indifferent_access
  end

  private

  def raw_message
    @data[:message] || {}
  end

  def evolution_type
    @data[:messageType].presence || raw_message.keys.find { |key| TYPE_MAP.key?(key.to_s) }.to_s
  end

  def type
    TYPE_MAP.fetch(evolution_type, 'unsupported')
  end

  def build_message
    message = { id: @data.dig(:key, :id), timestamp: @data[:messageTimestamp].to_s, type: type }
    message[:context] = { id: context_id } if context_id.present?
    message.merge(type_payload)
  end

  def type_payload
    case type
    when 'text' then { text: { body: text_body } }
    when 'location' then { location: location_payload }
    when 'image', 'video', 'audio', 'document', 'sticker' then { type.to_sym => media_payload }
    else {}
    end
  end

  def text_body
    raw_message[:conversation].presence ||
      raw_message.dig(:extendedTextMessage, :text).presence ||
      contact_card_text
  end

  def contact_card_text
    card = raw_message[:contactMessage]
    return if card.blank?

    phone = card[:vcard].to_s[/waid=(\d+)/, 1]
    ["📇 #{card[:displayName]}", phone].compact_blank.join(' ')
  end

  def media_node
    node = raw_message[evolution_type]
    node = {} unless node.is_a?(Hash)
    # documentWithCaptionMessage wraps the real document one level down.
    node.dig(:message, :documentMessage) || node
  end

  def media_payload
    node = media_node
    {
      id: @data.dig(:key, :id),
      caption: node[:caption],
      mime_type: node[:mimetype],
      filename: node[:fileName] || node[:title],
      base64: raw_message[:base64] || @data[:base64]
    }.compact
  end

  def location_payload
    node = raw_message[:locationMessage] || {}
    {
      latitude: node[:degreesLatitude],
      longitude: node[:degreesLongitude],
      name: node[:name],
      address: node[:address],
      url: node[:url]
    }.compact
  end

  def context_id
    node = raw_message[evolution_type]
    from_node = node.is_a?(Hash) ? node.dig(:contextInfo, :stanzaId) : nil
    from_node || @data.dig(:contextInfo, :stanzaId)
  end
end

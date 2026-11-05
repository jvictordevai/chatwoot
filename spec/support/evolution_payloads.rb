# Sample Evolution API v2 webhook payloads (Baileys), trimmed to the fields Chatwoot reads.
module EvolutionPayloads
  def evolution_text_payload(id: '3EB0TEXT001', from: '5511987654321', text: 'Olá, tudo bem?', from_me: false, push_name: 'Maria Cliente')
    {
      event: 'messages.upsert',
      instance: 'cw-1-1',
      data: {
        key: { remoteJid: "#{from}@s.whatsapp.net", fromMe: from_me, id: id },
        pushName: push_name,
        message: { conversation: text },
        messageType: 'conversation',
        messageTimestamp: 1_730_000_000
      }
    }
  end

  def evolution_image_payload(id: '3EB0IMG001', from: '5511987654321', base64: Base64.strict_encode64('fake-image-bytes'))
    {
      event: 'messages.upsert',
      instance: 'cw-1-1',
      data: {
        key: { remoteJid: "#{from}@s.whatsapp.net", fromMe: false, id: id },
        pushName: 'Maria Cliente',
        message: { imageMessage: { caption: 'Veja a foto', mimetype: 'image/jpeg' }, base64: base64 },
        messageType: 'imageMessage',
        messageTimestamp: 1_730_000_000
      }
    }
  end

  def evolution_group_payload
    evolution_text_payload.deep_merge(data: { key: { remoteJid: '120363000000000000@g.us' } })
  end

  def evolution_lid_payload(phone: '5511987654321')
    evolution_text_payload.deep_merge(data: { key: { remoteJid: '123456789012345@lid', senderPn: "#{phone}@s.whatsapp.net" } })
  end

  def evolution_status_payload(id:, status: 'READ')
    { event: 'messages.update', instance: 'cw-1-1', data: { keyId: id, remoteJid: '5511987654321@s.whatsapp.net', fromMe: true, status: status } }
  end

  def evolution_connection_payload(state: 'open', wuid: '5511912345678@s.whatsapp.net')
    { event: 'connection.update', instance: 'cw-1-1', data: { instance: 'cw-1-1', state: state, wuid: wuid, statusReason: 200 } }
  end
end

RSpec.configure do |config|
  config.include EvolutionPayloads
end

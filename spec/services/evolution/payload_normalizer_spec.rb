require 'rails_helper'

describe Evolution::PayloadNormalizer do
  describe '#message_params' do
    it 'maps a text message to the Meta incoming shape' do
      params = described_class.new(evolution_text_payload).message_params

      expect(params[:contacts].first).to include(wa_id: '5511987654321')
      expect(params[:contacts].first[:profile][:name]).to eq('Maria Cliente')
      expect(params[:messages].first).to include(id: '3EB0TEXT001', from: '5511987654321', type: 'text')
      expect(params[:messages].first[:text][:body]).to eq('Olá, tudo bem?')
    end

    it 'maps fromMe messages to message_echoes addressed to the contact' do
      normalizer = described_class.new(evolution_text_payload(from_me: true), business_number: '+5511900000000')
      params = normalizer.message_params

      expect(normalizer).to be_outgoing_echo
      expect(params[:message_echoes].first).to include(from: '5511900000000', to: '5511987654321', type: 'text')
    end

    it 'keeps the base64 media and caption for images' do
      media = described_class.new(evolution_image_payload).message_params[:messages].first

      expect(media[:type]).to eq('image')
      expect(media[:image]).to include(caption: 'Veja a foto', mime_type: 'image/jpeg', id: '3EB0IMG001')
      expect(media[:image][:base64]).to be_present
    end

    it 'maps extended text replies with the quoted message id as context' do
      payload = evolution_text_payload.deep_merge(
        data: { messageType: 'extendedTextMessage',
                message: { conversation: nil, extendedTextMessage: { text: 'respondendo', contextInfo: { stanzaId: 'QUOTED1' } } } }
      )
      message = described_class.new(payload).message_params[:messages].first

      expect(message[:text][:body]).to eq('respondendo')
      expect(message[:context][:id]).to eq('QUOTED1')
    end

    it 'resolves WhatsApp LIDs to the sender phone number' do
      params = described_class.new(evolution_lid_payload).message_params

      expect(params[:messages].first[:from]).to eq('5511987654321')
    end

    it 'ignores group messages' do
      expect(described_class.new(evolution_group_payload).message_params).to be_nil
    end

    it 'marks unknown message types as unsupported' do
      payload = evolution_text_payload.deep_merge(data: { messageType: 'pollCreationMessage', message: { conversation: nil } })

      expect(described_class.new(payload).message_params[:messages].first[:type]).to eq('unsupported')
    end
  end

  describe '#status_params' do
    it 'maps Evolution ack statuses to Chatwoot statuses' do
      params = described_class.new(evolution_status_payload(id: 'MSG1', status: 'DELIVERY_ACK')).status_params

      expect(params[:statuses].first).to eq('id' => 'MSG1', 'status' => 'delivered')
    end

    it 'returns nil for unknown statuses' do
      expect(described_class.new(evolution_status_payload(id: 'MSG1', status: 'PENDING')).status_params).to be_nil
    end
  end

  describe '#event' do
    it 'normalizes upper-case event names' do
      expect(described_class.new({ event: 'MESSAGES_UPSERT' }).event).to eq('messages.upsert')
    end
  end
end

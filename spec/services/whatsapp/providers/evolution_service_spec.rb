require 'rails_helper'

describe Whatsapp::Providers::EvolutionService do
  let(:channel) do
    create(:channel_whatsapp, provider: 'whatsapp_evolution', provider_config: { 'instance_name' => 'cw-1-1' },
                              sync_templates: false, validate_provider_config: false)
  end
  let(:conversation) { create(:conversation, inbox: channel.inbox) }
  let(:message) { create(:message, conversation: conversation, message_type: :outgoing, content: 'Olá!') }
  let(:client) { instance_double(Evolution::ApiClient) }
  let(:service) { described_class.new(whatsapp_channel: channel) }

  before { allow(Evolution::ApiClient).to receive(:new).and_return(client) }

  describe '#send_message' do
    it 'sends text and returns the WhatsApp message id' do
      allow(client).to receive(:send_text).and_return({ 'key' => { 'id' => 'SENT1' } })

      expect(service.send_message('5511987654321', message)).to eq('SENT1')
      expect(client).to have_received(:send_text).with('cw-1-1', number: '5511987654321', text: 'Olá!', quoted_id: nil)
    end

    it 'quotes the replied message' do
      quoted = create(:message, conversation: conversation, message_type: :incoming, source_id: 'Q1')
      message.update!(content_attributes: { in_reply_to: quoted.id })
      allow(client).to receive(:send_text).and_return({ 'key' => { 'id' => 'SENT2' } })

      service.send_message('5511987654321', message)

      expect(client).to have_received(:send_text).with('cw-1-1', hash_including(quoted_id: 'Q1'))
    end

    it 'sends image attachments as media' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: StringIO.new('img'), filename: 'foto.jpg', content_type: 'image/jpeg')
      message.save!
      allow(client).to receive(:send_media).and_return({ 'key' => { 'id' => 'MEDIA1' } })

      expect(service.send_message('5511987654321', message)).to eq('MEDIA1')
      expect(client).to have_received(:send_media).with('cw-1-1', hash_including(mediatype: 'image', mimetype: 'image/jpeg'))
    end

    it 'marks the message failed when Evolution errors' do
      allow(client).to receive(:send_text).and_raise(Evolution::ApiClient::Error, 'Evolution API error 400')

      expect(service.send_message('5511987654321', message)).to be_nil
      expect(message.reload.status).to eq('failed')
      expect(message.external_error).to include('400')
    end
  end

  it 'does not support templates' do
    expect(service.send_template('5511987654321', {}, message)).to be_nil
    expect(message.reload.status).to eq('failed')
  end

  it 'validates by instance name presence' do
    expect(service.validate_provider_config?).to be(true)
  end
end

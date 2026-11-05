require 'rails_helper'

RSpec.describe Webhooks::EvolutionEventsJob do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_evolution', phone_number: '+5511900000000',
                              provider_config: { 'instance_name' => 'cw-1-1' }, sync_templates: false, validate_provider_config: false)
  end
  let(:inbox) { channel.inbox }

  def perform(payload)
    described_class.perform_now(channel.id, payload.deep_stringify_keys)
  end

  it 'creates contact, conversation and incoming text message' do
    expect { perform(evolution_text_payload) }.to change(Message, :count).by(1)

    message = inbox.messages.last
    expect(message).to be_incoming
    expect(message.content).to eq('Olá, tudo bem?')
    expect(message.source_id).to eq('3EB0TEXT001')
    expect(message.sender.name).to eq('Maria Cliente')
    expect(message.sender.phone_number).to eq('+5511987654321')
  end

  it 'deduplicates repeated webhooks for the same message' do
    perform(evolution_text_payload)

    expect { perform(evolution_text_payload) }.not_to change(Message, :count)
  end

  it 'stores base64 images as attachments' do
    perform(evolution_image_payload)

    message = inbox.messages.last
    expect(message.content).to eq('Veja a foto')
    expect(message.attachments.first.file_type).to eq('image')
    expect(message.attachments.first.file).to be_attached
  end

  it 'records messages sent from the phone as outgoing echoes' do
    perform(evolution_text_payload(id: 'ECHO1', from_me: true, text: 'enviado do celular'))

    message = inbox.messages.last
    expect(message).to be_outgoing
    expect(message.content).to eq('enviado do celular')
    expect(message.content_attributes['external_echo']).to be(true)
  end

  it 'ignores group messages' do
    expect { perform(evolution_group_payload) }.not_to change(Message, :count)
  end

  it 'updates message status from acks' do
    perform(evolution_text_payload(id: 'OUT1', from_me: true))
    message = inbox.messages.find_by(source_id: 'OUT1')

    perform(evolution_status_payload(id: 'OUT1', status: 'READ'))

    expect(message.reload.status).to eq('read')
  end

  it 'swaps the placeholder phone number once connected' do
    channel.update!(phone_number: Channel::Whatsapp.evolution_placeholder_phone_number)
    allow(ActionCable.server).to receive(:broadcast)

    perform(evolution_connection_payload(state: 'open', wuid: '5511912345678:12@s.whatsapp.net'))

    expect(channel.reload.phone_number).to eq('+5511912345678')
    expect(channel.provider_config['connection_state']).to eq('open')
    expect(ActionCable.server).to have_received(:broadcast)
      .with("account_#{account.id}", hash_including(event: 'whatsapp_evolution.status_changed'))
  end

  it 'skips channels of other providers' do
    cloud = create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)

    expect { described_class.perform_now(cloud.id, evolution_text_payload.deep_stringify_keys) }.not_to change(Message, :count)
  end
end

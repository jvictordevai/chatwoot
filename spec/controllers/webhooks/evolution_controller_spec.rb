require 'rails_helper'

RSpec.describe 'Webhooks::EvolutionController', type: :request do
  let(:channel) do
    create(:channel_whatsapp, provider: 'whatsapp_evolution', provider_config: { 'instance_name' => 'cw-1-1' },
                              sync_templates: false, validate_provider_config: false)
  end
  let(:token) { channel.provider_config['webhook_token'] }

  it 'generates a webhook token for evolution channels' do
    expect(token.length).to eq(48)
  end

  it 'enqueues handled events for a valid token' do
    expect do
      post "/webhooks/evolution/#{token}", params: evolution_text_payload, as: :json
    end.to have_enqueued_job(Webhooks::EvolutionEventsJob).with(channel.id, hash_including('event' => 'messages.upsert'))

    expect(response).to have_http_status(:ok)
  end

  it 'delays fromMe echoes so outgoing sends are deduplicated' do
    post "/webhooks/evolution/#{token}", params: evolution_text_payload(from_me: true), as: :json

    expect(Webhooks::EvolutionEventsJob).to have_been_enqueued.at(a_value_within(2.seconds).of(5.seconds.from_now))
  end

  it 'acknowledges but ignores unhandled events' do
    expect do
      post "/webhooks/evolution/#{token}", params: { event: 'presence.update', data: {} }, as: :json
    end.not_to have_enqueued_job(Webhooks::EvolutionEventsJob)

    expect(response).to have_http_status(:ok)
  end

  it 'returns not found for unknown tokens' do
    post "/webhooks/evolution/#{'x' * 48}", params: evolution_text_payload, as: :json

    expect(response).to have_http_status(:not_found)
  end
end

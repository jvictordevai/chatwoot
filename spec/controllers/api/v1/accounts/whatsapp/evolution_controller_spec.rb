require 'rails_helper'

RSpec.describe 'WhatsApp Evolution (QR code) API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:client) { instance_double(Evolution::ApiClient) }
  let(:env) { { EVOLUTION_API_URL: 'http://evolution.test', EVOLUTION_API_KEY: 'key', FRONTEND_URL: 'https://chat.test' } }

  before { allow(Evolution::ApiClient).to receive(:new).and_return(client) }

  describe 'POST /whatsapp/evolution/connect' do
    let(:path) { "/api/v1/accounts/#{account.id}/whatsapp/evolution/connect" }

    it 'requires authentication' do
      post path

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns service unavailable when Evolution is not configured' do
      with_modified_env(EVOLUTION_API_URL: nil, EVOLUTION_API_KEY: nil) do
        post path, params: { inbox_name: 'Vendas' }, headers: administrator.create_new_auth_token, as: :json
      end

      expect(response).to have_http_status(:service_unavailable)
    end

    it 'forbids agents' do
      with_modified_env(env) do
        post path, params: { inbox_name: 'Vendas' }, headers: agent.create_new_auth_token, as: :json
      end

      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates the inbox and instance and returns the QR code' do
      allow(client).to receive(:create_instance).and_return({ 'qrcode' => { 'base64' => 'data:image/png;base64,QR', 'pairingCode' => 'ABCD1234' } })

      with_modified_env(env) do
        expect do
          post path, params: { inbox_name: 'Vendas' }, headers: administrator.create_new_auth_token, as: :json
        end.to change(Inbox, :count).by(1)
      end

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body).to include('name' => 'Vendas', 'qr_code' => 'data:image/png;base64,QR', 'pairing_code' => 'ABCD1234')
      channel = Inbox.find(body['id']).channel
      expect(channel.provider).to eq('whatsapp_evolution')
      expect(channel.provider_config['instance_name']).to match(/\Acw-#{account.id}-\h{12}\z/)
      expect(client).to have_received(:create_instance)
        .with(instance_name: channel.provider_config['instance_name'],
              webhook_url: "https://chat.test/webhooks/evolution/#{channel.provider_config['webhook_token']}")
    end

    it 'rolls back the inbox when Evolution fails' do
      allow(client).to receive(:create_instance).and_raise(Evolution::ApiClient::Error, 'Evolution API unreachable')
      allow(client).to receive(:delete_instance)

      with_modified_env(env) do
        expect do
          post path, params: { inbox_name: 'Vendas' }, headers: administrator.create_new_auth_token, as: :json
        end.not_to change(Inbox, :count)
      end

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'inbox scoped endpoints' do
    let!(:channel) do
      create(:channel_whatsapp, account: account, provider: 'whatsapp_evolution', provider_config: { 'instance_name' => 'cw-x' },
                                sync_templates: false, validate_provider_config: false)
    end

    it 'returns the current connection status' do
      allow(client).to receive(:connection_state).with('cw-x').and_return('open')

      with_modified_env(env) do
        get "/api/v1/accounts/#{account.id}/whatsapp/evolution/#{channel.inbox.id}/status", headers: administrator.create_new_auth_token
      end

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include('state' => 'open', 'connected' => true)
      expect(channel.reload.provider_config['connection_state']).to eq('open')
    end

    it 'returns a fresh QR code' do
      allow(client).to receive(:connect).with('cw-x').and_return({ 'base64' => 'QR2', 'pairingCode' => 'P2' })

      with_modified_env(env) do
        get "/api/v1/accounts/#{account.id}/whatsapp/evolution/#{channel.inbox.id}/qr", headers: administrator.create_new_auth_token
      end

      expect(response.parsed_body).to include('qr_code' => 'QR2', 'pairing_code' => 'P2', 'state' => 'connecting')
    end

    it 'logs out the session' do
      allow(client).to receive(:logout).with('cw-x')

      with_modified_env(env) do
        post "/api/v1/accounts/#{account.id}/whatsapp/evolution/#{channel.inbox.id}/logout", headers: administrator.create_new_auth_token
      end

      expect(response.parsed_body).to include('state' => 'close', 'connected' => false)
    end

    it 'returns not found for non-evolution inboxes' do
      cloud = create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)

      with_modified_env(env) do
        get "/api/v1/accounts/#{account.id}/whatsapp/evolution/#{cloud.inbox.id}/status", headers: administrator.create_new_auth_token
      end

      expect(response).to have_http_status(:not_found)
    end
  end
end

require 'rails_helper'

describe Evolution::ApiClient do
  let(:base_url) { 'http://evolution.test' }
  let(:client) { described_class.new(base_url: base_url, api_key: 'secret-key') }

  it 'raises when not configured' do
    expect { described_class.new(base_url: nil, api_key: nil) }.to raise_error(Evolution::ApiClient::NotConfiguredError)
  end

  describe '#create_instance' do
    it 'creates a Baileys instance with the Chatwoot webhook' do
      stub = stub_request(:post, "#{base_url}/instance/create")
             .with(headers: { 'apikey' => 'secret-key' }) do |request|
               body = JSON.parse(request.body)
               body['integration'] == 'WHATSAPP-BAILEYS' && body['qrcode'] == true &&
                 body.dig('webhook', 'url') == 'https://chat.test/webhooks/evolution/tok' &&
                 body.dig('webhook', 'events').include?('MESSAGES_UPSERT')
             end
             .to_return(status: 201, body: { qrcode: { base64: 'data:image/png;base64,AAA' } }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      response = client.create_instance(instance_name: 'cw-1-1', webhook_url: 'https://chat.test/webhooks/evolution/tok')

      expect(stub).to have_been_requested
      expect(response.dig('qrcode', 'base64')).to eq('data:image/png;base64,AAA')
    end
  end

  describe '#send_text' do
    it 'sends a quoted reply' do
      stub = stub_request(:post, "#{base_url}/message/sendText/cw-1-1")
             .with(body: { number: '5511987654321', text: 'oi', quoted: { key: { id: 'Q1' } } }.to_json)
             .to_return(status: 201, body: { key: { id: 'SENT1' } }.to_json, headers: { 'Content-Type' => 'application/json' })

      response = client.send_text('cw-1-1', number: '5511987654321', text: 'oi', quoted_id: 'Q1')

      expect(stub).to have_been_requested
      expect(response.dig('key', 'id')).to eq('SENT1')
    end
  end

  describe '#connection_state' do
    it 'returns the instance state' do
      stub_request(:get, "#{base_url}/instance/connectionState/cw-1-1")
        .to_return(status: 200, body: { instance: { state: 'open' } }.to_json, headers: { 'Content-Type' => 'application/json' })

      expect(client.connection_state('cw-1-1')).to eq('open')
    end
  end

  describe 'error handling' do
    it 'raises a typed error with the Evolution message' do
      stub_request(:post, "#{base_url}/message/sendText/cw-1-1")
        .to_return(status: 400, body: { status: 400, response: { message: ['number not on WhatsApp'] } }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect { client.send_text('cw-1-1', number: '1', text: 'x') }
        .to raise_error(Evolution::ApiClient::Error, /number not on WhatsApp/)
    end

    it 'wraps connection failures' do
      stub_request(:get, "#{base_url}/instance/connect/cw-1-1").to_raise(Errno::ECONNREFUSED)

      expect { client.connect('cw-1-1') }.to raise_error(Evolution::ApiClient::Error, /unreachable/)
    end
  end
end

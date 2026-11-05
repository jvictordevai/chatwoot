# Manages the Evolution API instance that backs a `whatsapp_evolution` channel.
# One Chatwoot inbox == one Evolution instance.
class Evolution::InstanceService
  CONNECTED_STATE = 'open'.freeze

  def initialize(channel, client: nil)
    @channel = channel
    @client = client
  end

  def create!
    response = client.create_instance(instance_name: instance_name, webhook_url: webhook_url)
    update_config('connection_state' => 'connecting')
    extract_qr(response['qrcode'])
  end

  # Returns { state:, qr_code:, pairing_code: } — qr_code is nil when already connected.
  def qr_code
    response = client.connect(instance_name)
    state = response.dig('instance', 'state')
    return status_payload(state) if state.present?

    status_payload('connecting').merge(extract_qr(response))
  end

  def refresh_status!
    state = client.connection_state(instance_name)
    update_config('connection_state' => state) if state.present?
    status_payload(state || connection_state)
  end

  def reconnect!
    client.set_webhook(instance_name: instance_name, webhook_url: webhook_url)
    qr_code
  end

  def logout!
    client.logout(instance_name)
    update_config('connection_state' => 'close')
    status_payload('close')
  end

  def delete!
    client.delete_instance(instance_name)
  rescue Evolution::ApiClient::Error => e
    # before_destroy must never block an inbox delete — log and move on.
    Rails.logger.error "[EVOLUTION] instance delete failed channel_id=#{@channel.id}: #{e.message}"
  end

  def status_payload(state = connection_state)
    {
      state: state,
      connected: state == CONNECTED_STATE,
      phone_number: @channel.evolution_connected_phone_number
    }
  end

  private

  def client
    @client ||= Evolution::ApiClient.new
  end

  def instance_name
    @channel.provider_config['instance_name']
  end

  def connection_state
    @channel.provider_config['connection_state']
  end

  def webhook_url
    "#{ENV.fetch('EVOLUTION_WEBHOOK_BASE_URL', ENV.fetch('FRONTEND_URL', nil))}/webhooks/evolution/#{@channel.provider_config['webhook_token']}"
  end

  def extract_qr(payload)
    payload ||= {}
    { qr_code: payload['base64'], pairing_code: payload['pairingCode'] }
  end

  def update_config(attrs)
    @channel.update!(provider_config: @channel.provider_config.merge(attrs))
  end
end

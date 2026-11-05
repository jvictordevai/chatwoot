# Handles Evolution `connection.update` / `qrcode.updated` events: persists the
# connection state, swaps the placeholder phone number for the real one once the
# QR code is scanned, and pushes the change to the dashboard over ActionCable.
class Evolution::ConnectionUpdateService
  def initialize(channel, event:, data:)
    @channel = channel
    @event = event
    @data = (data || {}).with_indifferent_access
  end

  def perform
    case @event
    when 'connection.update' then handle_connection_update
    when 'qrcode.updated' then broadcast(state: 'connecting', qr_code: @data.dig(:qrcode, :base64), pairing_code: @data.dig(:qrcode, :pairingCode))
    end
  end

  private

  def handle_connection_update
    state = @data[:state].to_s
    return if state.blank?

    attrs = { provider_config: @channel.provider_config.merge('connection_state' => state) }
    number = connected_number
    attrs[:phone_number] = "+#{number}" if state == 'open' && number.present? && phone_number_available?("+#{number}")
    @channel.update!(attrs)
    broadcast(state: state, connected: state == 'open', phone_number: @channel.evolution_connected_phone_number)
  end

  def connected_number
    @data[:wuid].to_s.split('@').first.to_s.split(':').first.presence
  end

  def phone_number_available?(number)
    return true if @channel.phone_number == number

    taken = Channel::Whatsapp.where.not(id: @channel.id).exists?(phone_number: number)
    Rails.logger.warn "[EVOLUTION] #{number} already used by another WhatsApp inbox; keeping placeholder" if taken
    !taken
  end

  def broadcast(payload)
    inbox = @channel.inbox
    return if inbox.blank?

    ActionCable.server.broadcast(
      "account_#{inbox.account_id}",
      { event: 'whatsapp_evolution.status_changed', data: payload.merge(inbox_id: inbox.id, account_id: inbox.account_id) }
    )
  end
end

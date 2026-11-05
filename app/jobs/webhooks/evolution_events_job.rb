class Webhooks::EvolutionEventsJob < MutexApplicationJob
  queue_as :low
  # Same budget as Webhooks::WhatsappEventsJob: retries must outlast the 30s lock TTL.
  retry_on LockAcquisitionError, wait: 2.seconds, attempts: 20

  def perform(channel_id, payload)
    channel = Channel::Whatsapp.find_by(id: channel_id, provider: 'whatsapp_evolution')
    return if channel.blank? || channel.inbox.blank? || !channel.account.active?

    normalizer = Evolution::PayloadNormalizer.new(payload, business_number: channel.evolution_connected_phone_number)
    case normalizer.event
    when 'messages.upsert' then process_message(channel, normalizer)
    when 'messages.update' then process_status(channel, normalizer)
    when 'connection.update', 'qrcode.updated'
      Evolution::ConnectionUpdateService.new(channel, event: normalizer.event, data: payload.with_indifferent_access[:data]).perform
    end
  end

  private

  def process_message(channel, normalizer)
    params = normalizer.message_params
    return if params.blank?

    key = format(::Redis::Alfred::WHATSAPP_MESSAGE_MUTEX, inbox_id: channel.inbox.id, sender_id: normalizer.contact_number)
    with_lock(key, 30.seconds) do
      Evolution::IncomingMessageService.new(inbox: channel.inbox, params: params, outgoing_echo: normalizer.outgoing_echo?).perform
    end
  end

  def process_status(channel, normalizer)
    params = normalizer.status_params
    return if params.blank?

    Evolution::IncomingMessageService.new(inbox: channel.inbox, params: params).perform
  end
end

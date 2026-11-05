# Receives Evolution API webhooks. Authenticated by the per-channel random token in the URL
# (Evolution can't sign payloads); unknown tokens get a 404 so instances can't be probed.
class Webhooks::EvolutionController < ActionController::API
  HANDLED_EVENTS = %w[messages.upsert messages.update connection.update qrcode.updated].freeze

  def process_payload
    channel = find_channel
    return head :not_found if channel.blank?

    event = params[:event].to_s.downcase.tr('_', '.')
    return head :ok unless HANDLED_EVENTS.include?(event)

    payload = params.to_unsafe_hash.except(:controller, :action, :webhook_token, :apikey)
    job = Webhooks::EvolutionEventsJob
    # Messages sent from Chatwoot echo back as fromMe upserts; give the send job time to
    # persist the source_id so the echo is deduplicated instead of duplicated.
    job = job.set(wait: 5.seconds) if event == 'messages.upsert' && params.dig(:data, :key, :fromMe).to_s == 'true'
    job.perform_later(channel.id, payload)
    head :ok
  end

  private

  def find_channel
    token = params[:webhook_token].to_s
    return if token.length < 32

    Channel::Whatsapp.where(provider: 'whatsapp_evolution').find_by("provider_config->>'webhook_token' = ?", token)
  end
end

# Creates a `whatsapp_evolution` channel + inbox and its Evolution instance,
# returning the first QR code so the agent can scan it right away.
class Evolution::ChannelCreationService
  attr_reader :channel, :qr_payload

  def initialize(account:, inbox_name:, client: nil)
    @account = account
    @inbox_name = inbox_name.to_s.strip
    @client = client
  end

  def perform
    raise ArgumentError, 'inbox_name is required' if @inbox_name.blank?

    create_channel_and_inbox
    @qr_payload = Evolution::InstanceService.new(@channel, client: @client).create!
    self
  rescue Evolution::ApiClient::Error
    # Roll back the half-created inbox so the agent can retry cleanly.
    if @channel&.persisted?
      # Destroying the inbox also destroys its channel (and the Evolution instance, best effort).
      Inbox.find_by(channel: @channel)&.destroy!
      Channel::Whatsapp.find_by(id: @channel.id)&.destroy!
    end
    raise
  end

  private

  def create_channel_and_inbox
    ActiveRecord::Base.transaction do
      @channel = @account.whatsapp_channels.create!(
        phone_number: Channel::Whatsapp.evolution_placeholder_phone_number,
        provider: 'whatsapp_evolution',
        provider_config: { 'instance_name' => "cw-#{@account.id}-#{SecureRandom.hex(6)}" }
      )
      @account.inboxes.create!(name: @inbox_name, channel: @channel)
    end
  end
end

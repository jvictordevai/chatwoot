# Dashboard endpoints for WhatsApp QR code inboxes (Evolution API provider).
class Api::V1::Accounts::Whatsapp::EvolutionController < Api::V1::Accounts::BaseController
  before_action :ensure_configured
  before_action :authorize_create, only: [:connect]
  before_action :fetch_inbox, except: [:connect]

  def connect
    setup = Evolution::ChannelCreationService.new(account: Current.account, inbox_name: params[:inbox_name]).perform
    inbox = setup.channel.inbox
    render json: { id: inbox.id, name: inbox.name, state: 'connecting' }.merge(setup.qr_payload), status: :created
  rescue CustomExceptions::Inbox::LimitExceeded => e
    render_error_response(e)
  rescue ArgumentError, ActiveRecord::RecordInvalid, Evolution::ApiClient::Error => e
    render_evolution_error(e)
  end

  def qr
    render json: instance_service.qr_code
  rescue Evolution::ApiClient::Error => e
    render_evolution_error(e)
  end

  # Not named `status`: that would shadow ActionController's response status.
  def connection_status
    render json: instance_service.refresh_status!
  rescue Evolution::ApiClient::Error => e
    render_evolution_error(e)
  end

  def reconnect
    render json: instance_service.reconnect!
  rescue Evolution::ApiClient::Error => e
    render_evolution_error(e)
  end

  def logout
    render json: instance_service.logout!
  rescue Evolution::ApiClient::Error => e
    render_evolution_error(e)
  end

  private

  def ensure_configured
    return if Evolution::ApiClient.configured?

    render json: { message: 'WhatsApp QR code is not configured on this installation' }, status: :service_unavailable
  end

  def authorize_create
    authorize ::Inbox, :create?
  end

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @inbox, :update?
    raise ActiveRecord::RecordNotFound unless @inbox.channel.is_a?(Channel::Whatsapp) && @inbox.channel.evolution_provider?
  end

  def instance_service
    @instance_service ||= Evolution::InstanceService.new(@inbox.channel)
  end

  def render_evolution_error(error)
    Rails.logger.error "[EVOLUTION] account_id=#{Current.account.id} error=#{error.class}: #{error.message}"
    render json: { message: error.message }, status: :unprocessable_entity
  end
end

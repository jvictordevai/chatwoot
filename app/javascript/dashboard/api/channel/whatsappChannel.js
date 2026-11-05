/* global axios */
import ApiClient from '../ApiClient';

class WhatsappChannel extends ApiClient {
  constructor() {
    super('whatsapp', { accountScoped: true });
  }

  createEmbeddedSignup(params) {
    return axios.post(`${this.baseUrl()}/whatsapp/authorization`, params);
  }

  requestEmbeddedSignupAccess(useCase) {
    return axios.post(`${this.baseUrl()}/whatsapp/access_request`, {
      use_case: useCase,
    });
  }

  reauthorizeWhatsApp({ inboxId, ...params }) {
    return axios.post(`${this.baseUrl()}/whatsapp/authorization`, {
      ...params,
      inbox_id: inboxId,
    });
  }

  previewManualSetup(params) {
    return axios.post(`${this.baseUrl()}/whatsapp/manual/preview`, params);
  }

  connectManualSetup(params) {
    return axios.post(`${this.baseUrl()}/whatsapp/manual/connect`, params);
  }

  getManualWebhookStatus(inboxId) {
    return axios.get(
      `${this.baseUrl()}/whatsapp/manual/${inboxId}/webhook_status`
    );
  }

  setupManualWebhook(inboxId) {
    return axios.post(
      `${this.baseUrl()}/whatsapp/manual/${inboxId}/setup_webhook`
    );
  }

  // WhatsApp QR code (Evolution API provider)
  connectEvolution(params) {
    return axios.post(`${this.baseUrl()}/whatsapp/evolution/connect`, params);
  }

  getEvolutionQr(inboxId) {
    return axios.get(`${this.baseUrl()}/whatsapp/evolution/${inboxId}/qr`);
  }

  getEvolutionStatus(inboxId) {
    return axios.get(`${this.baseUrl()}/whatsapp/evolution/${inboxId}/status`);
  }

  reconnectEvolution(inboxId) {
    return axios.post(
      `${this.baseUrl()}/whatsapp/evolution/${inboxId}/reconnect`
    );
  }

  logoutEvolution(inboxId) {
    return axios.post(`${this.baseUrl()}/whatsapp/evolution/${inboxId}/logout`);
  }
}

export default new WhatsappChannel();

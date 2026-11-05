import { flushPromises, mount } from '@vue/test-utils';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import EvolutionQrPanel from '../EvolutionQrPanel.vue';

const api = vi.hoisted(() => ({
  getEvolutionStatus: vi.fn(),
  getEvolutionQr: vi.fn(),
  reconnectEvolution: vi.fn(),
  logoutEvolution: vi.fn(),
}));

vi.mock('dashboard/api/channel/whatsappChannel', () => ({ default: api }));
vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));

const mountPanel = (props = {}) =>
  mount(EvolutionQrPanel, {
    props: { inboxId: 7, ...props },
    global: {
      stubs: {
        Button: {
          props: ['label'],
          emits: ['click'],
          template: '<button @click="$emit(\'click\')">{{ label }}</button>',
        },
        Icon: true,
      },
    },
  });

describe('EvolutionQrPanel', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    Object.values(api).forEach(fn => fn.mockReset());
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('shows the QR code while the session is connecting', async () => {
    api.getEvolutionStatus.mockResolvedValue({ data: { state: 'connecting' } });
    api.getEvolutionQr.mockResolvedValue({
      data: { state: 'connecting', qr_code: 'AAA', pairing_code: 'PAIR1234' },
    });

    const wrapper = mountPanel();
    await flushPromises();

    const img = wrapper.find('[data-testid="evolution-qr-image"]');
    expect(img.attributes('src')).toBe('data:image/png;base64,AAA');
    expect(wrapper.text()).toContain('PAIR1234');
  });

  it('emits connected once polling reports an open session', async () => {
    api.getEvolutionStatus
      .mockResolvedValueOnce({ data: { state: 'connecting' } })
      .mockResolvedValue({
        data: {
          state: 'open',
          connected: true,
          phone_number: '+5511912345678',
        },
      });
    api.getEvolutionQr.mockResolvedValue({ data: { qr_code: 'AAA' } });

    const wrapper = mountPanel();
    await flushPromises();
    await vi.advanceTimersByTimeAsync(3000);
    await flushPromises();

    expect(wrapper.emitted('connected')).toBeTruthy();
    expect(
      wrapper.find('[data-testid="evolution-connected"]').text()
    ).toContain('+5511912345678');
  });

  it('does not request a QR code when already connected', async () => {
    api.getEvolutionStatus.mockResolvedValue({ data: { state: 'open' } });

    mountPanel();
    await flushPromises();

    expect(api.getEvolutionQr).not.toHaveBeenCalled();
  });

  it('shows the API error message when Evolution is unreachable', async () => {
    const error = {
      response: { data: { message: 'Evolution API unreachable' } },
    };
    api.getEvolutionStatus.mockRejectedValue(error);
    api.getEvolutionQr.mockRejectedValue(error);

    const wrapper = mountPanel();
    await flushPromises();

    expect(wrapper.find('[data-testid="evolution-error"]').text()).toBe(
      'Evolution API unreachable'
    );
  });
});

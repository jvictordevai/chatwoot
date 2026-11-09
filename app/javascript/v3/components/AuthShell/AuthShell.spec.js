import { mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import AuthShell from './AuthShell.vue';

const store = createStore({
  modules: {
    globalConfig: {
      namespaced: true,
      getters: {
        get: () => ({
          installationName: 'Community',
          logo: '/brand-assets/logo.svg',
          logoDark: '/brand-assets/logo_dark.svg',
        }),
      },
    },
  },
});

const mountShell = (props = {}, slots = {}) =>
  mount(AuthShell, {
    props,
    slots,
    global: { plugins: [store], mocks: { $t: key => key } },
  });

describe('AuthShell', () => {
  it('renders the title, subtitle and the form slot', () => {
    const wrapper = mountShell(
      { title: 'Bem-vindo de volta', subtitle: 'Entre para continuar' },
      { default: '<form data-testid="slot-form" />' }
    );

    expect(wrapper.get('[data-testid="auth-title"]').text()).toBe(
      'Bem-vindo de volta'
    );
    expect(wrapper.text()).toContain('Entre para continuar');
    expect(wrapper.find('[data-testid="slot-form"]').exists()).toBe(true);
  });

  it('shows the brand panel with the light-on-dark Community logo', () => {
    const wrapper = mountShell({ title: 'x' });
    const panel = wrapper.get('[data-testid="auth-brand-panel"]');

    expect(panel.find('img').attributes('src')).toBe(
      '/brand-assets/logo_dark.svg'
    );
    expect(panel.text()).toContain('LOGIN.BRAND.HEADLINE_HIGHLIGHT');
  });

  it('hides the heading when no title is given (MFA and session screens)', () => {
    const wrapper = mountShell();

    expect(wrapper.find('[data-testid="auth-title"]').exists()).toBe(false);
  });
});

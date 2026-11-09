<script>
import SnackbarContainer from './components/SnackBar/Container.vue';
import { isDarkColorScheme } from 'dashboard/helper/themeHelper';

export default {
  components: { SnackbarContainer },
  data() {
    return { theme: 'light' };
  },
  mounted() {
    this.applyColorTheme(
      window.matchMedia('(prefers-color-scheme: dark)').matches
    );
    this.listenToThemeChanges();
    this.setLocale(window.chatwootConfig.selectedLocale);
  },
  methods: {
    // Same rule as the dashboard: light by default, dark or OS ('auto') when
    // the user picked it in the Appearance menu.
    applyColorTheme(isOSOnDarkMode) {
      const isDark = isDarkColorScheme(isOSOnDarkMode);
      this.theme = isDark ? 'dark' : 'light';
      document.documentElement.classList.toggle('dark', isDark);
    },
    listenToThemeChanges() {
      const mql = window.matchMedia('(prefers-color-scheme: dark)');
      mql.onchange = e => this.applyColorTheme(e.matches);
    },
    setLocale(locale) {
      if (locale) {
        this.$root.$i18n.locale = locale;
      }
    },
  },
};
</script>

<template>
  <div class="h-full min-h-screen w-full antialiased" :class="theme">
    <router-view />
    <SnackbarContainer />
  </div>
</template>

<style lang="scss">
@tailwind base;
@tailwind components;
@tailwind utilities;

@import '../dashboard/assets/scss/next-colors';
@import 'shared/assets/fonts/inter';
@import 'shared/assets/fonts/poppins';

html,
body {
  font-family:
    'Inter',
    -apple-system,
    BlinkMacSystemFont,
    'Segoe UI',
    Roboto,
    Oxygen-Sans,
    Ubuntu,
    Cantarell,
    'Helvetica Neue',
    sans-serif;
  @apply h-full w-full;

  input,
  select {
    outline: none;
  }
}

.text-link {
  @apply text-n-brand font-medium hover:text-n-blue-10;
}

.v-popper--theme-tooltip .v-popper__inner {
  background: black !important;
  font-size: 0.75rem;
  padding: 4px 8px !important;
  border-radius: 6px;
  font-weight: 400;
}

.v-popper--theme-tooltip .v-popper__arrow-container {
  display: none;
}
</style>

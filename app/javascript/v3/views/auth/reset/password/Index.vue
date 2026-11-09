<script>
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required, minLength, email } from '@vuelidate/validators';
import { useBranding } from 'shared/composables/useBranding';
import FormInput from '../../../../components/Form/Input.vue';
import { resetPassword } from '../../../../api/auth';
import NextButton from 'dashboard/components-next/button/Button.vue';
import AuthShell from '../../../../components/AuthShell/AuthShell.vue';

export default {
  components: { AuthShell, FormInput, NextButton },
  props: {
    redirectUrl: { type: String, default: '' },
    ssoAccountId: { type: String, default: '' },
  },
  setup() {
    const { replaceInstallationName } = useBranding();
    return { v$: useVuelidate(), replaceInstallationName };
  },
  data() {
    return {
      credentials: { email: '' },
      resetPassword: {
        message: '',
        showLoading: false,
      },
      error: '',
    };
  },
  validations() {
    return {
      credentials: {
        email: {
          required,
          email,
          minLength: minLength(4),
        },
      },
    };
  },
  computed: {
    loginRoute() {
      const route = { name: 'login' };
      return this.redirectUrl
        ? {
            ...route,
            query: {
              redirect_url: this.redirectUrl,
              ...(this.ssoAccountId
                ? { sso_account_id: this.ssoAccountId }
                : {}),
            },
          }
        : route;
    },
  },
  methods: {
    showAlertMessage(message) {
      // Reset loading, current selected agent
      this.resetPassword.showLoading = false;
      useAlert(message);
    },
    submit() {
      this.resetPassword.showLoading = true;
      resetPassword({
        ...this.credentials,
        redirectUrl: this.redirectUrl,
        ssoAccountId: this.ssoAccountId,
      })
        .then(res => {
          let successMessage = this.$t('RESET_PASSWORD.API.SUCCESS_MESSAGE');
          if (res.data && res.data.message) {
            successMessage = res.data.message;
          }
          this.showAlertMessage(successMessage);
        })
        .catch(error => {
          let errorMessage = this.$t('RESET_PASSWORD.API.ERROR_MESSAGE');
          if (error?.response?.data?.message) {
            errorMessage = error.response.data.message;
          }
          this.showAlertMessage(errorMessage);
        });
    },
  },
};
</script>

<template>
  <AuthShell
    :title="$t('RESET_PASSWORD.TITLE')"
    :subtitle="replaceInstallationName($t('RESET_PASSWORD.DESCRIPTION'))"
  >
    <form @submit.prevent="submit">
      <div class="space-y-5">
        <FormInput
          v-model="credentials.email"
          name="email_address"
          :has-error="v$.credentials.email.$error"
          :error-message="$t('RESET_PASSWORD.EMAIL.ERROR')"
          :placeholder="$t('RESET_PASSWORD.EMAIL.PLACEHOLDER')"
          @input="v$.credentials.email.$touch"
        />
        <NextButton
          lg
          type="submit"
          data-testid="submit_button"
          class="w-full"
          :label="$t('RESET_PASSWORD.SUBMIT')"
          :disabled="v$.credentials.email.$invalid || resetPassword.showLoading"
          :is-loading="resetPassword.showLoading"
        />
      </div>
      <p class="mt-6 text-sm text-n-slate-11">
        {{ $t('RESET_PASSWORD.GO_BACK_TO_LOGIN') }}
        <router-link :to="loginRoute" class="text-link">
          {{ $t('COMMON.CLICK_HERE') }}.
        </router-link>
      </p>
    </form>
  </AuthShell>
</template>

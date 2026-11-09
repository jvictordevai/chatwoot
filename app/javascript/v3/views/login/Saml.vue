<script setup>
import { ref, nextTick, computed, onMounted } from 'vue';
import { required, email } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

// components
import FormInput from '../../components/Form/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import AuthShell from '../../components/AuthShell/AuthShell.vue';

const props = defineProps({
  ssoAccountId: { type: String, default: '' },
  authError: {
    type: String,
    default: '',
  },
  target: {
    type: String,
    default: 'web',
  },
  redirectUrl: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();

const credentials = ref({
  email: '',
});

const loginApi = ref({
  showLoading: false,
  hasErrored: false,
});

const handleAuthError = () => {
  if (!props.authError) {
    return;
  }

  const translatedMessage = t('LOGIN.SAML.API.ERROR_MESSAGE');
  useAlert(translatedMessage);
  loginApi.value.hasErrored = true;
};

const validations = {
  credentials: {
    email: {
      required,
      email,
    },
  },
};

const v$ = useVuelidate(validations, { credentials });

const csrfToken = ref('');
const loginRoute = computed(() => {
  const route = { name: 'login' };
  return props.redirectUrl || props.ssoAccountId
    ? {
        ...route,
        query: {
          redirect_url: props.redirectUrl,
          ...(props.ssoAccountId ? { sso_account_id: props.ssoAccountId } : {}),
        },
      }
    : route;
});

onMounted(async () => {
  csrfToken.value =
    document
      .querySelector('meta[name="csrf-token"]')
      ?.getAttribute('content') || '';

  await nextTick(handleAuthError);
});
</script>

<template>
  <AuthShell
    :title="t('LOGIN.SAML.TITLE')"
    :subtitle="t('LOGIN.SAML.SUBTITLE')"
  >
    <section :class="{ 'animate-wiggle': loginApi.hasErrored }">
      <form class="space-y-5" method="POST" action="/api/v1/auth/saml_login">
        <FormInput
          v-model="credentials.email"
          name="email"
          type="text"
          :tabindex="1"
          required
          :label="t('LOGIN.SAML.WORK_EMAIL.LABEL')"
          :placeholder="t('LOGIN.SAML.WORK_EMAIL.PLACEHOLDER')"
          :has-error="v$.credentials.email.$error"
          @input="v$.credentials.email.$touch"
        />
        <input
          type="hidden"
          class="h-0"
          name="authenticity_token"
          :value="csrfToken"
        />
        <input type="hidden" class="h-0" name="target" :value="target" />
        <input
          v-if="redirectUrl"
          type="hidden"
          class="h-0"
          name="redirect_url"
          :value="redirectUrl"
        />
        <input
          v-if="ssoAccountId"
          type="hidden"
          name="sso_account_id"
          :value="ssoAccountId"
        />
        <NextButton
          lg
          type="submit"
          class="w-full"
          :tabindex="2"
          :label="t('LOGIN.SAML.SUBMIT')"
          :disabled="loginApi.showLoading"
          :is-loading="loginApi.showLoading"
        />
      </form>
    </section>
    <p class="mt-6 text-sm text-n-slate-11">
      <router-link :to="loginRoute" class="text-link">
        {{ t('LOGIN.SAML.BACK_TO_LOGIN') }}
      </router-link>
    </p>
  </AuthShell>
</template>

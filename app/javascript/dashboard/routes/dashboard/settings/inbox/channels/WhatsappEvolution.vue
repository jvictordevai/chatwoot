<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore } from 'vuex';
import WhatsappChannelAPI from 'dashboard/api/channel/whatsappChannel';
import Banner from 'dashboard/components-next/banner/Banner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import EvolutionQrPanel from './whatsapp/EvolutionQrPanel.vue';

const { t } = useI18n();
const router = useRouter();
const store = useStore();

const inboxName = ref('');
const isLoading = ref(false);
const errorMessage = ref('');
const inbox = ref(null);
const isConnected = ref(false);

const createInbox = async () => {
  if (!inboxName.value.trim()) {
    errorMessage.value = t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION.ERRORS.NAME');
    return;
  }
  isLoading.value = true;
  errorMessage.value = '';
  try {
    const { data } = await WhatsappChannelAPI.connectEvolution({
      inbox_name: inboxName.value.trim(),
    });
    inbox.value = data;
  } catch (error) {
    errorMessage.value =
      error?.response?.data?.message ||
      t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION.ERRORS.GENERIC');
  } finally {
    isLoading.value = false;
  }
};

const onConnected = () => {
  isConnected.value = true;
};

const continueToAgents = async () => {
  await store.dispatch('inboxes/get');
  router.replace({
    name: 'settings_inboxes_add_agents',
    params: { page: 'new', inbox_id: inbox.value.id },
  });
};
</script>

<template>
  <div class="flex flex-col gap-6" data-testid="whatsapp-evolution-setup">
    <div class="text-start">
      <h2 class="mb-2 text-lg font-medium text-n-slate-12">
        {{ t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION.TITLE') }}
      </h2>
      <p class="text-sm text-n-slate-11">
        {{ t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION.DESCRIPTION') }}
      </p>
    </div>

    <Banner color="amber" class="w-full">
      <span class="text-start">
        {{ t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION.UNOFFICIAL_WARNING') }}
      </span>
    </Banner>

    <form
      v-if="!inbox"
      class="flex flex-col gap-4"
      @submit.prevent="createInbox"
    >
      <Input
        v-model="inboxName"
        :label="t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION.INBOX_NAME')"
        :placeholder="
          t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION.INBOX_NAME_PLACEHOLDER')
        "
        data-testid="evolution-inbox-name"
      />
      <p v-if="errorMessage" class="text-sm text-n-ruby-11">
        {{ errorMessage }}
      </p>
      <div>
        <Button
          type="submit"
          :label="t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION.ACTIONS.GENERATE_QR')"
          :is-loading="isLoading"
          data-testid="evolution-generate-qr"
        />
      </div>
    </form>

    <template v-else>
      <EvolutionQrPanel
        :inbox-id="inbox.id"
        :initial-qr-code="inbox.qr_code || ''"
        :initial-pairing-code="inbox.pairing_code || ''"
        @connected="onConnected"
      />
      <div class="flex justify-end pt-5 border-t border-n-weak">
        <Button
          :label="t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION.ACTIONS.CONTINUE')"
          :disabled="!isConnected"
          icon="i-lucide-arrow-right"
          trailing-icon
          data-testid="evolution-continue"
          @click="continueToAgents"
        />
      </div>
    </template>
  </div>
</template>

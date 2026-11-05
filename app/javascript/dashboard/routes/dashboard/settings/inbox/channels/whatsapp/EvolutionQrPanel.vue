<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import WhatsappChannelAPI from 'dashboard/api/channel/whatsappChannel';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  inboxId: { type: [Number, String], required: true },
  initialQrCode: { type: String, default: '' },
  initialPairingCode: { type: String, default: '' },
});

const emit = defineEmits(['connected', 'disconnected']);

const STATUS_POLL_INTERVAL = 3000;
const QR_REFRESH_INTERVAL = 25000;

const { t } = useI18n();

const state = ref('connecting');
const qrCode = ref(props.initialQrCode);
const pairingCode = ref(props.initialPairingCode);
const phoneNumber = ref('');
const errorMessage = ref('');
const isBusy = ref(false);
let statusTimer = null;
let qrTimer = null;

const isConnected = computed(() => state.value === 'open');
const qrImageSrc = computed(() => {
  if (!qrCode.value) return '';
  return qrCode.value.startsWith('data:')
    ? qrCode.value
    : `data:image/png;base64,${qrCode.value}`;
});

const extractError = error =>
  error?.response?.data?.message ||
  t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION.ERRORS.GENERIC');

const applyPayload = payload => {
  if (!payload) return;
  if (payload.state) state.value = payload.state;
  if (payload.qr_code) qrCode.value = payload.qr_code;
  if (payload.pairing_code) pairingCode.value = payload.pairing_code;
  if (payload.phone_number) phoneNumber.value = payload.phone_number;
};

const stopTimers = () => {
  clearInterval(statusTimer);
  clearInterval(qrTimer);
  statusTimer = null;
  qrTimer = null;
};

const fetchQr = async () => {
  try {
    const { data } = await WhatsappChannelAPI.getEvolutionQr(props.inboxId);
    applyPayload(data);
    errorMessage.value = '';
  } catch (error) {
    errorMessage.value = extractError(error);
  }
};

const fetchStatus = async () => {
  try {
    const { data } = await WhatsappChannelAPI.getEvolutionStatus(props.inboxId);
    applyPayload(data);
  } catch (error) {
    errorMessage.value = extractError(error);
  }
};

const startTimers = () => {
  stopTimers();
  statusTimer = setInterval(fetchStatus, STATUS_POLL_INTERVAL);
  qrTimer = setInterval(fetchQr, QR_REFRESH_INTERVAL);
};

const reconnect = async () => {
  isBusy.value = true;
  try {
    const { data } = await WhatsappChannelAPI.reconnectEvolution(props.inboxId);
    applyPayload(data);
    errorMessage.value = '';
    if (!isConnected.value) startTimers();
  } catch (error) {
    errorMessage.value = extractError(error);
  } finally {
    isBusy.value = false;
  }
};

const logout = async () => {
  isBusy.value = true;
  try {
    const { data } = await WhatsappChannelAPI.logoutEvolution(props.inboxId);
    applyPayload(data);
    qrCode.value = '';
    pairingCode.value = '';
    emit('disconnected');
  } catch (error) {
    errorMessage.value = extractError(error);
  } finally {
    isBusy.value = false;
  }
};

watch(isConnected, connected => {
  if (connected) {
    stopTimers();
    emit('connected', { phoneNumber: phoneNumber.value });
  }
});

onMounted(async () => {
  await fetchStatus();
  if (isConnected.value) return;
  if (!qrCode.value) await fetchQr();
  startTimers();
});

onBeforeUnmount(stopTimers);

defineExpose({ reconnect, logout, state });
</script>

<template>
  <div class="flex flex-col gap-4" data-testid="evolution-qr-panel">
    <div
      v-if="isConnected"
      class="flex items-center gap-3 p-4 rounded-xl border border-n-teal-6 bg-n-teal-2"
      data-testid="evolution-connected"
    >
      <Icon icon="i-lucide-circle-check" class="size-5 text-n-teal-11" />
      <div class="flex-1 min-w-0">
        <p class="text-sm font-medium text-n-slate-12">
          {{ t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION.CONNECTED') }}
        </p>
        <p v-if="phoneNumber" class="text-sm text-n-slate-11">
          {{ phoneNumber }}
        </p>
      </div>
      <Button
        :label="t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION.ACTIONS.DISCONNECT')"
        variant="outline"
        color="ruby"
        sm
        :is-loading="isBusy"
        @click="logout"
      />
    </div>

    <div v-else class="flex flex-col gap-4 md:flex-row md:items-start">
      <div
        class="flex items-center justify-center flex-shrink-0 bg-white border rounded-xl size-64 border-n-weak"
      >
        <img
          v-if="qrImageSrc"
          :src="qrImageSrc"
          :alt="t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION.QR_ALT')"
          class="size-60"
          data-testid="evolution-qr-image"
        />
        <Icon
          v-else
          icon="i-lucide-loader-circle"
          class="size-8 animate-spin text-n-slate-10"
        />
      </div>
      <div class="flex flex-col gap-3 text-sm text-n-slate-11">
        <p class="font-medium text-n-slate-12">
          {{ t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION.SCAN_TITLE') }}
        </p>
        <ol class="ps-4 list-decimal flex flex-col gap-1">
          <li>{{ t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION.STEPS.STEP_1') }}</li>
          <li>{{ t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION.STEPS.STEP_2') }}</li>
          <li>{{ t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION.STEPS.STEP_3') }}</li>
        </ol>
        <p v-if="pairingCode">
          {{ t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION.PAIRING_CODE') }}
          <span class="font-mono font-medium text-n-slate-12">
            {{ pairingCode }}
          </span>
        </p>
        <p class="text-xs">
          {{ t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION.QR_REFRESH_HINT') }}
        </p>
        <div>
          <Button
            :label="t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION.ACTIONS.NEW_QR')"
            variant="outline"
            color="slate"
            sm
            :is-loading="isBusy"
            @click="reconnect"
          />
        </div>
      </div>
    </div>

    <p
      v-if="errorMessage"
      class="text-sm text-n-ruby-11"
      data-testid="evolution-error"
    >
      {{ errorMessage }}
    </p>
  </div>
</template>

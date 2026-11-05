<script>
import PageHeader from '../../SettingsSubPageHeader.vue';
import BandwidthSms from './BandwidthSms.vue';

// CCA fork: Twilio SMS removed; Bandwidth is the only SMS provider.
export default {
  components: {
    PageHeader,
    BandwidthSms,
  },
};
</script>

<template>
  <div class="h-full w-full p-6 col-span-6">
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.SMS.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.SMS.DESC')"
    />
    <BandwidthSms />
  </div>
</template>

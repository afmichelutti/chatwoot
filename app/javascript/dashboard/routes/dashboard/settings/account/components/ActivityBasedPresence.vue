<script setup>
import { ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import SectionLayout from './SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import Switch from 'next/switch/Switch.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import NextInput from 'next/input/Input.vue';

const { t } = useI18n();
const isEnabled = ref(false);
const inactivityTimeoutMinutes = ref(10);
const busyTimeoutHours = ref(3);
const isSubmitting = ref(false);

const { currentAccount, updateAccount } = useAccount();

watch(
  currentAccount,
  () => {
    const {
      activity_based_presence_enabled,
      activity_based_presence_config,
    } = currentAccount.value || {};

    isEnabled.value = activity_based_presence_enabled || false;

    if (activity_based_presence_config) {
      inactivityTimeoutMinutes.value = activity_based_presence_config.inactivity_timeout_minutes || 10;
      busyTimeoutHours.value = activity_based_presence_config.busy_timeout_hours || 3;
    }
  },
  { deep: true, immediate: true }
);

const updateAccountSettings = async (enabled, config) => {
  try {
    isSubmitting.value = true;
    await updateAccount({
      activity_based_presence_enabled: enabled,
      activity_based_presence_config: config,
    }, { silent: true });
    useAlert(t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.API.SUCCESS'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.API.ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};

const handleSubmit = async () => {
  if (inactivityTimeoutMinutes.value < 1) {
    useAlert(t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.INACTIVITY_TIMEOUT.ERROR'));
    return Promise.resolve();
  }

  if (busyTimeoutHours.value < 1) {
    useAlert(t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.BUSY_TIMEOUT.ERROR'));
    return Promise.resolve();
  }

  return updateAccountSettings(true, {
    inactivity_timeout_minutes: inactivityTimeoutMinutes.value,
    busy_timeout_hours: busyTimeoutHours.value,
  });
};

const handleDisable = async () => {
  return updateAccountSettings(false, {
    inactivity_timeout_minutes: 10,
    busy_timeout_hours: 3,
  });
};

const toggleActivityPresence = async () => {
  if (!isEnabled.value) {
    handleDisable();
  } else {
    handleSubmit();
  }
};
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.NOTE')"
    :hide-content="!isEnabled"
    with-border
  >
    <template #headerActions>
      <div class="flex justify-end">
        <Switch v-model="isEnabled" @change="toggleActivityPresence" />
      </div>
    </template>

    <form class="grid gap-5" @submit.prevent="handleSubmit">
      <WithLabel
        :label="t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.INACTIVITY_TIMEOUT.LABEL')"
        :help-message="t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.INACTIVITY_TIMEOUT.HELP')"
      >
        <div class="flex gap-2 items-center">
          <NextInput
            v-model.number="inactivityTimeoutMinutes"
            type="number"
            min="1"
            max="999"
            class="w-32"
          />
          <span class="text-sm text-n-slate-11">
            {{ t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.MINUTES') }}
          </span>
        </div>
      </WithLabel>

      <WithLabel
        :label="t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.BUSY_TIMEOUT.LABEL')"
        :help-message="t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.BUSY_TIMEOUT.HELP')"
      >
        <div class="flex gap-2 items-center">
          <NextInput
            v-model.number="busyTimeoutHours"
            type="number"
            min="1"
            max="999"
            class="w-32"
          />
          <span class="text-sm text-n-slate-11">
            {{ t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.HOURS') }}
          </span>
        </div>
      </WithLabel>

      <div class="flex gap-2">
        <NextButton
          blue
          type="submit"
          :is-loading="isSubmitting"
          :label="t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.UPDATE_BUTTON')"
        />
      </div>
    </form>
  </SectionLayout>
</template>

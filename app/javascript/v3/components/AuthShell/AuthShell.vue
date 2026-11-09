<script setup>
import { useMapGetter } from 'dashboard/composables/store';

defineProps({
  title: { type: String, default: '' },
  subtitle: { type: String, default: '' },
});

const globalConfig = useMapGetter('globalConfig/get');
const currentYear = new Date().getFullYear();
</script>

<template>
  <main
    class="grid w-full min-h-screen bg-white lg:grid-cols-[minmax(0,1.05fr)_minmax(0,1fr)] dark:bg-n-background"
  >
    <!-- Brand panel: Community dark art with the blue/red light trails -->
    <aside
      data-testid="auth-brand-panel"
      class="relative flex-col justify-between hidden p-12 overflow-hidden text-white lg:flex xl:p-16 bg-[#03050B] isolate"
    >
      <div
        class="absolute rounded-full pointer-events-none -top-48 -left-40 size-[38rem] bg-[#0092FF] opacity-25 blur-[140px] -z-10"
      />
      <div
        class="absolute rounded-full pointer-events-none -bottom-56 -right-48 size-[34rem] bg-[#FF0000] opacity-20 blur-[140px] -z-10"
      />
      <svg
        class="absolute inset-0 w-full h-full pointer-events-none -z-10"
        viewBox="0 0 800 1000"
        preserveAspectRatio="xMidYMid slice"
        fill="none"
        aria-hidden="true"
      >
        <defs>
          <linearGradient id="auth-trail-blue" x1="0" y1="1" x2="1" y2="0">
            <stop offset="0" stop-color="#0092FF" stop-opacity="0" />
            <stop offset="0.55" stop-color="#0092FF" />
            <stop offset="1" stop-color="#7CC8FF" stop-opacity="0.2" />
          </linearGradient>
          <linearGradient id="auth-trail-red" x1="1" y1="0" x2="0" y2="1">
            <stop offset="0" stop-color="#FF0000" stop-opacity="0" />
            <stop offset="0.5" stop-color="#FF0000" />
            <stop offset="1" stop-color="#FF5A5A" stop-opacity="0.15" />
          </linearGradient>
          <filter
            id="auth-trail-glow"
            x="-20%"
            y="-20%"
            width="140%"
            height="140%"
          >
            <feGaussianBlur stdDeviation="9" />
          </filter>
        </defs>
        <g opacity="0.9">
          <path
            d="M-120 600C120 560 380 360 500 -60"
            stroke="url(#auth-trail-blue)"
            stroke-width="14"
            filter="url(#auth-trail-glow)"
            opacity="0.55"
          />
          <path
            d="M-120 600C120 560 380 360 500 -60"
            stroke="url(#auth-trail-blue)"
            stroke-width="1.6"
          />
          <path
            d="M-120 690C160 640 420 420 560 -60"
            stroke="url(#auth-trail-blue)"
            stroke-width="1"
            opacity="0.35"
          />
        </g>
        <g opacity="0.9">
          <path
            d="M940 560C700 600 520 800 470 1080"
            stroke="url(#auth-trail-red)"
            stroke-width="14"
            filter="url(#auth-trail-glow)"
            opacity="0.5"
          />
          <path
            d="M940 560C700 600 520 800 470 1080"
            stroke="url(#auth-trail-red)"
            stroke-width="1.6"
          />
          <path
            d="M940 660C740 700 590 860 560 1080"
            stroke="url(#auth-trail-red)"
            stroke-width="1"
            opacity="0.35"
          />
        </g>
      </svg>
      <div
        class="absolute inset-x-0 bottom-0 h-px bg-gradient-to-r from-transparent via-white/15 to-transparent"
      />

      <img
        :src="globalConfig.logoDark"
        :alt="globalConfig.installationName"
        class="w-auto h-10 self-start"
      />

      <div class="max-w-md">
        <p
          class="text-xs font-medium tracking-[0.18em] uppercase text-white/55"
        >
          {{ $t('LOGIN.BRAND.EYEBROW') }}
        </p>
        <h1
          class="mt-5 text-4xl font-semibold leading-[1.15] tracking-tight font-poppins xl:text-[2.75rem]"
        >
          {{ $t('LOGIN.BRAND.HEADLINE_START') }}
          <span
            class="text-transparent bg-clip-text bg-gradient-to-r from-[#3AAEFF] via-white to-[#FF4D4D]"
          >
            {{ $t('LOGIN.BRAND.HEADLINE_HIGHLIGHT') }}
          </span>
        </h1>
        <p class="mt-5 text-base leading-relaxed text-white/65">
          {{ $t('LOGIN.BRAND.DESCRIPTION') }}
        </p>
      </div>

      <p class="text-xs text-white/40">
        {{ $t('LOGIN.BRAND.COPYRIGHT', { year: currentYear }) }}
      </p>
    </aside>

    <!-- Form column -->
    <section class="flex flex-col min-h-screen px-6 py-10 sm:px-12">
      <div
        class="flex flex-col justify-center flex-1 w-full max-w-[400px] mx-auto"
      >
        <img
          :src="globalConfig.logo"
          :alt="globalConfig.installationName"
          class="block w-auto h-9 mb-12 self-start lg:hidden dark:hidden"
        />
        <img
          v-if="globalConfig.logoDark"
          :src="globalConfig.logoDark"
          :alt="globalConfig.installationName"
          class="hidden w-auto h-9 mb-12 self-start dark:block lg:dark:hidden"
        />

        <header v-if="title" class="mb-8">
          <h2
            data-testid="auth-title"
            class="text-[1.75rem] font-semibold tracking-tight font-poppins text-n-slate-12"
          >
            {{ title }}
          </h2>
          <p v-if="subtitle" class="mt-2 text-sm leading-6 text-n-slate-11">
            {{ subtitle }}
          </p>
          <slot name="header" />
        </header>

        <slot />
      </div>

      <footer class="mt-10 text-xs text-center text-n-slate-10">
        <slot name="footer" />
      </footer>
    </section>
  </main>
</template>

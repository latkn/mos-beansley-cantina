<script setup>
import { computed } from 'vue'

const props = defineProps({
  guest: { type: Object, required: true },
  compact: Boolean,
})

const allergiesList = computed(() => {
  const a = props.guest?.allergies
  if (Array.isArray(a)) return a
  if (typeof a === 'string') return a ? [a] : []
  return []
})
</script>

<template>
  <article
    class="rounded-xl border border-cantina-border bg-cantina-card overflow-hidden shadow-cantina"
    :class="compact ? 'p-3' : 'p-4'"
  >
    <div class="flex items-start gap-3">
      <div class="flex-shrink-0 w-14 h-14 rounded-full bg-cantina-surface border border-cantina-border overflow-hidden">
        <img
          v-if="guest.avatar_url"
          :src="guest.avatar_url"
          :alt="guest.callsign"
          class="w-full h-full object-cover"
        />
        <div v-else class="w-full h-full flex items-center justify-center text-xl font-mono text-cantina-muted">
          {{ (guest.callsign || '?').slice(0, 2) }}
        </div>
      </div>
      <div class="min-w-0 flex-1">
        <div class="font-mono font-bold text-cantina-cream uppercase tracking-wider">
          {{ guest.callsign }}
        </div>
        <div v-if="guest.race?.name" class="mt-1 text-cantina-sand text-sm">
          Раса по биометрии: {{ guest.race.name }}
        </div>
        <!-- Аллергии крупно — видно бариста и гостю -->
        <div
          v-if="allergiesList.length"
          class="mt-3 px-4 py-3 rounded-xl bg-cantina-amber/15 border-2 border-cantina-amber/70"
        >
          <div class="text-cantina-amber font-bold uppercase tracking-wider text-sm mb-1">Аллергия</div>
          <div class="text-cantina-cream font-mono text-xl md:text-2xl leading-tight">{{ allergiesList.join(', ') }}</div>
        </div>
      </div>
    </div>
  </article>
</template>

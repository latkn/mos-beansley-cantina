<script setup>
import { ref, onMounted } from 'vue'
import { getActivePlanets } from '@/api/planets'
import PlanetCompleteModal from '@/components/PlanetCompleteModal.vue'

const TASK_DURATION_SEC = 5 * 60

const activePlanets = ref([])
const modalPlanet = ref(null)
const modalOpen = ref(false)
const now = ref(Date.now())
let interval = null

function planetTimeLeft(planet) {
  const task = planet?.task
  if (!task?.created_at) return 0
  const end = new Date(task.created_at).getTime() + TASK_DURATION_SEC * 1000
  return Math.max(0, Math.ceil((end - now.value) / 1000))
}

function planetOverdue(planet) {
  return planet?.task?.created_at && Date.now() > new Date(planet.task.created_at).getTime() + TASK_DURATION_SEC * 1000
}

async function load() {
  activePlanets.value = await getActivePlanets()
}

function openModal(planet) {
  modalPlanet.value = planet
  modalOpen.value = true
}

function onDone() {
  load()
}

/** Классы границы/цвета карточки планеты по сложности (1–5). */
function planetDifficultyClass(planet) {
  const d = planet?.task?.difficulty ?? 3
  const map = {
    1: 'border-cantina-success/50 hover:border-cantina-success',
    2: 'border-cantina-copper/50 hover:border-cantina-copper-light',
    3: 'border-cantina-amber/50 hover:border-cantina-amber',
    4: 'border-cantina-copper-light/50 hover:border-cantina-copper',
    5: 'border-cantina-danger/50 hover:border-cantina-danger',
  }
  return map[d] || map[3]
}

onMounted(() => {
  load()
  interval = setInterval(() => {
    now.value = Date.now()
  }, 1000)
})

import { onUnmounted } from 'vue'
onUnmounted(() => {
  if (interval) clearInterval(interval)
})
</script>

<template>
  <div class="min-h-screen bg-cantina-bg text-cantina-cream p-4 font-sans">
    <div class="max-w-lg mx-auto">
      <h1 class="font-display text-xl font-semibold text-cantina-amber mb-2">Завершить задание</h1>
      <p class="text-cantina-muted text-sm mb-6">
        Выберите свою планету (группу), приложите фото и нажмите «Завершить».
      </p>

      <div v-if="activePlanets.length === 0" class="text-cantina-muted py-8">
        Нет активных заданий.
      </div>

      <ul v-else class="space-y-3">
        <li v-for="planet in activePlanets"
            :key="planet.id">
          <button
            type="button"
            :class="['w-full text-left rounded-xl border-2 bg-cantina-card p-4 transition-colors', planetDifficultyClass(planet)]"
            @click="openModal(planet)"
          >
            <div class="font-mono text-cantina-copper font-bold">{{ planet.name }}</div>
            <p v-if="planet.task" class="text-cantina-sand text-sm mt-1 line-clamp-2">
              {{ planet.task.task_text }}
            </p>
            <div v-if="planet.members?.length" class="flex flex-wrap gap-1.5 mt-2">
              <div
                v-for="m in planet.members"
                :key="m.id"
                class="flex items-center gap-1.5 shrink-0"
                :title="m.callsign"
              >
                <div class="w-7 h-7 rounded-full overflow-hidden bg-cantina-surface border border-cantina-border flex-shrink-0">
                  <img
                    v-if="m.avatar_url"
                    :src="m.avatar_url"
                    :alt="m.callsign"
                    class="w-full h-full object-cover"
                  />
                  <div v-else class="w-full h-full flex items-center justify-center text-cantina-muted text-xs font-bold">
                    {{ (m.callsign || '?').slice(0, 1) }}
                  </div>
                </div>
                <span class="text-cantina-muted text-xs font-mono truncate max-w-[4rem]">{{ m.callsign }}</span>
              </div>
            </div>
            <div class="flex items-center gap-2 mt-2 text-xs">
              <span v-if="planetOverdue(planet)" class="px-2 py-0.5 rounded bg-cantina-amber/30 text-cantina-amber">Просрочено</span>
              <span v-else class="font-mono tabular-nums text-cantina-copper">
                {{ Math.floor(planetTimeLeft(planet) / 60) }}:{{ String(planetTimeLeft(planet) % 60).padStart(2, '0') }}
              </span>
              <span class="text-cantina-muted">{{ planet.members?.length ?? 0 }} уч.</span>
            </div>
          </button>
        </li>
      </ul>
    </div>

    <PlanetCompleteModal
      v-model="modalOpen"
      :planet="modalPlanet"
      @done="onDone"
    />
  </div>
</template>

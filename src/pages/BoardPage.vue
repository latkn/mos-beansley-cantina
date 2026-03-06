<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { getPendingOrders, getReadyForPickupOrders, subscribeOrders } from '@/api/orders'
import { getActivePlanet, getGuestIdsWithCompletedTask } from '@/api/planets'

const preparing = ref([])
const readyForPickup = ref([])
const activePlanet = ref(null)
const guestIdsTaskCompleted = ref(new Set())
const loading = ref(true)

async function load() {
  loading.value = true
  try {
    const [pending, ready, planet, taskCompletedIds] = await Promise.all([
      getPendingOrders(),
      getReadyForPickupOrders(),
      getActivePlanet(),
      getGuestIdsWithCompletedTask(),
    ])
    preparing.value = pending
    readyForPickup.value = ready
    activePlanet.value = planet
    guestIdsTaskCompleted.value = taskCompletedIds
  } finally {
    loading.value = false
  }
}

function hasTaskCompleted(order) {
  return order?.guest_id && guestIdsTaskCompleted.value.has(order.guest_id)
}

let planetPollInterval = null
function startPlanetPolling() {
  planetPollInterval = setInterval(async () => {
    const [p, ids] = await Promise.all([
      getActivePlanet(),
      getGuestIdsWithCompletedTask(),
    ])
    activePlanet.value = p
    guestIdsTaskCompleted.value = ids
  }, 5000)
}
function stopPlanetPolling() {
  if (planetPollInterval) clearInterval(planetPollInterval)
}

const unsub = subscribeOrders(load)
onMounted(() => {
  load()
  startPlanetPolling()
})
onUnmounted(() => {
  unsub()
  stopPlanetPolling()
})
</script>

<template>
  <div class="min-h-screen bg-cantina-bg text-cantina-cream p-4 md:p-6 font-sans">
    <div class="max-w-5xl mx-auto">
      <h1 class="font-display text-2xl text-cantina-cream font-semibold mb-2">Табло</h1>
      <p class="text-cantina-muted text-sm mb-6">
        Готовится → Готово к выдаче. Подходи, когда твой позывной в правой колонке.
      </p>

      <!-- Срочное задание для расы (когда штаб объединил 4+ одной расы) -->
      <section
        v-if="activePlanet?.task && activePlanet.members?.length"
        class="mb-8 rounded-xl border-2 border-cantina-amber bg-cantina-amber/15 p-6 shadow-cantina"
      >
        <div class="text-cantina-amber font-display font-bold text-xl md:text-2xl uppercase tracking-wider mb-2">
          Срочно! {{ activePlanet.name }}
        </div>
        <p class="text-lg text-cantina-cream font-mono mb-3">{{ activePlanet.task.task_text }}</p>
        <p class="text-cantina-sand font-semibold text-lg">Сделайте фотоотчёт!</p>
        <div class="flex flex-wrap gap-2 mt-3">
          <span
            v-for="m in activePlanet.members"
            :key="m.id"
            class="px-3 py-1 rounded-full bg-cantina-amber/30 text-cantina-cream text-sm font-mono"
          >
            {{ m.callsign }}
          </span>
        </div>
      </section>

      <div v-if="loading && !preparing.length && !readyForPickup.length" class="text-cantina-muted py-4">Загрузка…</div>

      <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-8">
        <!-- Колонка: Готовится -->
        <section class="card-cantina rounded-xl border-2 border-cantina-copper/50 p-6">
          <h2 class="font-display text-xl font-semibold text-cantina-copper mb-4 flex items-center gap-2">
            <span class="w-3 h-3 rounded-full bg-cantina-copper animate-pulse" />
            Готовится
          </h2>
          <ul class="space-y-3 min-h-[160px]">
            <li
              v-for="(order, index) in preparing"
              :key="order.id"
              class="flex items-center gap-4 p-4 rounded-xl bg-cantina-surface border border-cantina-border"
            >
              <span class="flex-shrink-0 w-10 h-10 rounded-full bg-cantina-copper/40 text-cantina-cream flex items-center justify-center text-lg font-bold">
                {{ index + 1 }}
              </span>
              <div class="w-12 h-12 rounded-full bg-cantina-surface overflow-hidden flex-shrink-0 border border-cantina-border">
                <img
                  v-if="order.guest?.avatar_url"
                  :src="order.guest.avatar_url"
                  :alt="order.callsign"
                  class="w-full h-full object-cover"
                />
                <div v-else class="w-full h-full flex items-center justify-center text-cantina-muted font-bold">
                  {{ (order.callsign || '?').slice(0, 2) }}
                </div>
              </div>
              <div class="w-10 h-10 rounded-lg bg-cantina-bg border border-cantina-border overflow-hidden flex-shrink-0">
                <img
                  v-if="order.image_url"
                  :src="order.image_url"
                  :alt="order.coffee_name"
                  class="w-full h-full object-cover"
                />
                <div v-else class="w-full h-full flex items-center justify-center text-cantina-muted">
                  <span class="material-icons text-lg">local_cafe</span>
                </div>
              </div>
              <div class="min-w-0 flex-1">
                <div class="font-mono font-bold text-cantina-cream uppercase tracking-wider text-lg">{{ order.callsign }}</div>
                <div v-if="order.coffee_name" class="text-cantina-muted text-sm">{{ order.coffee_name }}</div>
                <span
                  v-if="hasTaskCompleted(order)"
                  class="inline-flex items-center gap-1 mt-1 px-2 py-0.5 rounded text-xs font-bold uppercase tracking-wider bg-cantina-success/30 text-cantina-success border border-cantina-success/50"
                >
                  Задание выполнено
                </span>
              </div>
            </li>
          </ul>
          <p v-if="!preparing.length" class="text-cantina-muted py-8 text-center">Пусто</p>
        </section>

        <!-- Колонка: Готово к выдаче -->
        <section class="card-cantina rounded-xl border-2 border-cantina-success/50 p-6">
          <h2 class="font-display text-xl font-semibold text-cantina-success mb-4 flex items-center gap-2">
            <span class="w-3 h-3 rounded-full bg-cantina-success" />
            Готово к выдаче
          </h2>
          <ul class="space-y-3 min-h-[160px]">
            <li
              v-for="order in readyForPickup"
              :key="order.id"
              class="flex items-center gap-4 p-4 rounded-xl bg-cantina-surface border border-cantina-success/40"
            >
              <div class="w-14 h-14 rounded-full bg-cantina-surface overflow-hidden flex-shrink-0 border border-cantina-border">
                <img
                  v-if="order.guest?.avatar_url"
                  :src="order.guest.avatar_url"
                  :alt="order.callsign"
                  class="w-full h-full object-cover"
                />
                <div v-else class="w-full h-full flex items-center justify-center text-cantina-muted font-bold text-lg">
                  {{ (order.callsign || '?').slice(0, 2) }}
                </div>
              </div>
              <div class="w-10 h-10 rounded-lg bg-cantina-bg border border-cantina-border overflow-hidden flex-shrink-0">
                <img
                  v-if="order.image_url"
                  :src="order.image_url"
                  :alt="order.coffee_name"
                  class="w-full h-full object-cover"
                />
                <div v-else class="w-full h-full flex items-center justify-center text-cantina-muted">
                  <span class="material-icons text-lg">local_cafe</span>
                </div>
              </div>
              <div class="min-w-0 flex-1">
                <div class="font-mono font-bold text-cantina-cream uppercase tracking-wider text-lg">{{ order.callsign }}</div>
                <div class="text-cantina-success/90">Кофе готов, подходи!</div>
                <div v-if="order.coffee_name" class="text-cantina-muted text-sm">{{ order.coffee_name }}</div>
                <span
                  v-if="hasTaskCompleted(order)"
                  class="inline-flex items-center gap-1 mt-1 px-2 py-0.5 rounded text-xs font-bold uppercase tracking-wider bg-cantina-success/30 text-cantina-success border border-cantina-success/50"
                >
                  Задание выполнено
                </span>
              </div>
            </li>
          </ul>
          <p v-if="!readyForPickup.length" class="text-cantina-muted py-8 text-center">Пусто</p>
        </section>
      </div>

      <div class="mt-10 pb-8 sticky bottom-4">
        <div class="bg-cantina-bg/70 backdrop-blur-sm rounded-xl border border-cantina-border p-3">
          <router-link
            to="/register"
            class="btn-cantina-primary w-full py-6 font-mono text-xl uppercase tracking-wider text-center block"
          >
            Регистрация
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

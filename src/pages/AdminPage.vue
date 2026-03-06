<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { getOrdersInQueue, subscribeOrders } from '@/api/orders'
import {
  getActivePlanets,
  getGuestsUnavailableForPlanetIds,
  getExtremenessLevel,
  getExtremenessLevelName,
  completePlanet,
} from '@/api/planets'
import PlanetCompleteModal from '@/components/PlanetCompleteModal.vue'

/** Код штаба для отмены задания (4 цифры из Звёздных войн: блок Леи — 2187) */
const STAFF_CODE = '2187'

const ordersInQueue = ref([])
const activePlanets = ref([])
const guestsUnavailableIds = ref(new Set())
const modalPlanet = ref(null)
const modalOpen = ref(false)
const now = ref(Date.now())
const cancelPlanetId = ref(null)
const cancelCode = ref('')
const cancelError = ref('')
const cancelSubmitting = ref(false)
const TASK_DURATION_SEC = 5 * 60
let nowInterval = null

function planetTimeLeft(planet) {
  const task = planet?.task
  if (!task?.created_at) return 0
  const end = new Date(task.created_at).getTime() + TASK_DURATION_SEC * 1000
  return Math.max(0, Math.ceil((end - now.value) / 1000))
}

function planetOverdue(planet) {
  return planet?.task?.created_at && Date.now() > new Date(planet.task.created_at).getTime() + TASK_DURATION_SEC * 1000
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

async function loadAll() {
  const [orders, planets] = await Promise.all([
    getOrdersInQueue(),
    getActivePlanets(),
  ])
  ordersInQueue.value = orders
  activePlanets.value = planets
  const ids = await getGuestsUnavailableForPlanetIds()
  guestsUnavailableIds.value = ids
}

/** Три планеты по уровню экстрима (1 — лёгкий, 2 — медиум, 3 — экстремальный). Только гости в очереди, не в активной планете. */
const queueByExtremenessLevel = computed(() => {
  const inActive = guestsUnavailableIds.value
  const levels = [
    { level: 1, name: getExtremenessLevelName(1), orders: [] },
    { level: 2, name: getExtremenessLevelName(2), orders: [] },
    { level: 3, name: getExtremenessLevelName(3), orders: [] },
  ]
  for (const order of ordersInQueue.value) {
    const g = order.guest
    if (!g || inActive.has(g.id)) continue
    const level = getExtremenessLevel(g)
    const row = levels.find((l) => l.level === level)
    if (row) row.orders.push(order)
  }
  return levels
})

const totalInCircles = computed(() =>
  queueByExtremenessLevel.value.reduce((sum, r) => sum + r.orders.length, 0)
)

function openModal(planet) {
  modalPlanet.value = planet
  modalOpen.value = true
}

function onPlanetDone() {
  loadAll()
}

const unsub = subscribeOrders(() => {
  loadAll()
})

onMounted(async () => {
  await loadAll()
  nowInterval = setInterval(() => { now.value = Date.now() }, 1000)
})
onUnmounted(() => {
  unsub()
  if (nowInterval) clearInterval(nowInterval)
})

function openCancelConfirm(planet, e) {
  e.stopPropagation()
  cancelPlanetId.value = planet.id
  cancelCode.value = ''
  cancelError.value = ''
}

function closeCancelConfirm() {
  cancelPlanetId.value = null
  cancelCode.value = ''
  cancelError.value = ''
}

async function confirmCancelTask() {
  if (!cancelPlanetId.value || cancelSubmitting.value) return
  if (cancelCode.value.trim() !== STAFF_CODE) {
    cancelError.value = 'Неверный код штаба'
    return
  }
  const idToComplete = cancelPlanetId.value
  cancelSubmitting.value = true
  cancelError.value = ''
  try {
    await completePlanet(idToComplete)
    closeCancelConfirm()
    if (modalPlanet.value?.id === idToComplete) {
      modalOpen.value = false
      modalPlanet.value = null
    }
    await loadAll()
  } catch (e) {
    cancelError.value = e?.message || 'Ошибка'
  } finally {
    cancelSubmitting.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-cantina-bg text-cantina-cream font-sans flex flex-col">
    <!-- Верхняя полоса: счётчик и ссылка на терминал тамады -->
    <header class="flex-shrink-0 p-4 md:p-6 border-b border-cantina-border bg-cantina-surface">
      <div class="max-w-4xl mx-auto flex flex-wrap items-center gap-4">
        <h1 class="font-display text-xl md:text-2xl font-semibold text-cantina-amber">Штаб заданий</h1>
        <span class="text-cantina-muted text-sm">
          В кружках: <span class="text-cantina-cream font-bold">{{ totalInCircles }}</span>
        </span>
        <router-link
          to="/admin/tamada"
          class="ml-auto px-4 py-2 rounded-xl bg-cantina-copper hover:bg-cantina-copper-light text-cantina-bg font-mono font-bold uppercase tracking-wider transition-colors"
        >
          Терминал тамады
        </router-link>
      </div>
    </header>

    <!-- Три планеты по уровню экстрима -->
    <section class="flex-1 min-h-0 flex items-center justify-center p-4 md:p-6">
      <div class="flex flex-wrap justify-center gap-6 md:gap-10">
        <div
          v-for="group in queueByExtremenessLevel"
          :key="group.level"
          class="rounded-2xl border-2 bg-cantina-card flex flex-col items-center overflow-hidden transition-all hover:scale-105 shadow-cantina w-[min(22vmin,180px)]"
          :class="{
            'border-cantina-success/50': group.level === 1,
            'border-cantina-copper/50': group.level === 2,
            'border-cantina-danger/50': group.level === 3,
          }"
        >
          <div
            class="font-display font-bold text-sm md:text-base truncate px-2 pt-3 w-full text-center"
            :class="{
              'text-cantina-success': group.level === 1,
              'text-cantina-copper': group.level === 2,
              'text-cantina-danger': group.level === 3,
            }"
          >
            {{ group.name }}
          </div>
          <div class="flex flex-wrap justify-center gap-1 p-2 flex-1 items-center min-h-[80px] content-center">
            <template v-for="(order, j) in group.orders" :key="order.id">
              <div
                class="w-9 h-9 md:w-11 md:h-11 rounded-full bg-cantina-surface overflow-hidden flex-shrink-0 border border-cantina-border"
                :title="order.callsign"
              >
                <img
                  v-if="order.guest?.avatar_url"
                  :src="order.guest.avatar_url"
                  :alt="order.callsign"
                  class="w-full h-full object-cover"
                />
                <div
                  v-else
                  class="w-full h-full flex items-center justify-center text-cantina-muted text-sm"
                >
                  ?
                </div>
              </div>
            </template>
          </div>
          <div class="text-cantina-muted text-sm font-mono pb-3">
            {{ group.orders?.length ?? 0 }}
          </div>
        </div>
      </div>
    </section>

    <div class="flex-shrink-0 max-w-4xl mx-auto w-full p-4 md:p-6">

      <!-- Активные планеты: клик → модалка -->
      <section class="mb-6">
        <h2 class="font-display text-lg font-semibold text-cantina-amber mb-3">Активные задания</h2>
        <div v-if="activePlanets.length === 0" class="text-cantina-muted py-4">
          Нет активных планет. Запуск заданий — в <router-link to="/admin/tamada" class="text-cantina-copper hover:underline">Терминале тамады</router-link>.
        </div>
        <div v-else class="grid gap-4 md:grid-cols-2">
          <button
            v-for="planet in activePlanets"
            :key="planet.id"
            type="button"
            :class="['text-left rounded-xl border-2 bg-cantina-card p-4 transition-colors', planetDifficultyClass(planet)]"
            @click="openModal(planet)"
          >
            <div class="font-mono font-bold text-cantina-copper">{{ planet.name }}</div>
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
            <div class="flex items-center gap-2 mt-2 text-xs flex-wrap">
              <span v-if="planetOverdue(planet)" class="px-2 py-0.5 rounded bg-cantina-amber/30 text-cantina-amber">Просрочено</span>
              <span v-else class="font-mono tabular-nums text-cantina-copper">
                {{ Math.floor(planetTimeLeft(planet) / 60) }}:{{ String(planetTimeLeft(planet) % 60).padStart(2, '0') }}
              </span>
              <span class="text-cantina-muted">{{ planet.members?.length ?? 0 }} уч. · нажмите для фото</span>
              <button
                type="button"
                class="ml-auto px-2 py-1 rounded text-cantina-muted hover:text-cantina-danger hover:bg-cantina-danger/10 text-xs transition-colors"
                title="Отменить задание (нужен код штаба)"
                @click="openCancelConfirm(planet, $event)"
              >
                Отменить
              </button>
            </div>
          </button>
        </div>
      </section>

      <p class="text-cantina-muted text-sm">
        <router-link to="/admin/tamada" class="text-cantina-copper hover:text-cantina-copper-light transition-colors">Терминал тамады</router-link>
        · <router-link to="/admin/tasks" class="text-cantina-copper hover:text-cantina-copper-light transition-colors">Редактировать задания</router-link>
        · <router-link to="/admin/reports" class="text-cantina-copper hover:text-cantina-copper-light transition-colors">Отчёты по заданиям</router-link>
        · Участники: <router-link to="/tamada" class="text-cantina-copper hover:text-cantina-copper-light transition-colors">открыть с телефона</router-link> для загрузки фото.
      </p>
    </div>

    <PlanetCompleteModal
      v-model="modalOpen"
      :planet="modalPlanet"
      @done="onPlanetDone"
    />

    <!-- Модалка подтверждения отмены задания по коду штаба -->
    <Teleport to="body">
      <div
        v-if="cancelPlanetId"
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60"
        @click.self="closeCancelConfirm"
      >
        <div class="bg-cantina-card border-2 border-cantina-copper rounded-xl p-6 max-w-sm w-full shadow-cantina">
          <h3 class="font-display text-lg font-semibold text-cantina-amber mb-2">Отменить задание</h3>
          <p class="text-cantina-sand text-sm mb-4">
            Введите код штаба (4 цифры). Задание будет снято без фотоотчёта.
          </p>
          <input
            v-model="cancelCode"
            type="password"
            inputmode="numeric"
            maxlength="4"
            autocomplete="off"
            placeholder="••••"
            class="w-full px-3 py-2 rounded-lg bg-cantina-surface border border-cantina-border text-cantina-cream font-mono text-center text-xl tracking-[0.5em] focus:ring-2 focus:ring-cantina-copper"
            @keydown.enter="confirmCancelTask"
          />
          <p v-if="cancelError" class="mt-2 text-cantina-danger text-sm">{{ cancelError }}</p>
          <div class="flex gap-2 mt-4">
            <button
              type="button"
              class="flex-1 py-2 rounded-lg bg-cantina-copper hover:bg-cantina-copper-light text-cantina-bg font-semibold disabled:opacity-50"
              :disabled="cancelSubmitting"
              @click="confirmCancelTask"
            >
              {{ cancelSubmitting ? '…' : 'Подтвердить' }}
            </button>
            <button
              type="button"
              class="px-4 py-2 rounded-lg border border-cantina-border text-cantina-sand hover:bg-cantina-surface"
              @click="closeCancelConfirm"
            >
              Отмена
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

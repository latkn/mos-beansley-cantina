<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { getOrdersInQueue, subscribeOrders } from '@/api/orders'
import {
  getActivePlanets,
  getGuestsUnavailableForPlanetIds,
  getExtremenessLevel,
  getExtremenessLevelName,
  createPlanetFromGuests,
  completePlanet,
  replacePlanetTask,
} from '@/api/planets'
import { getRandomTamadaTaskByLevel, difficultyToExtremenessLevel } from '@/api/tamadaTasks'

const ordersInQueue = ref([])
const activePlanets = ref([])
const guestsUnavailableIds = ref(new Set())
const selectedGuestIds = ref(new Set()) // { level: Set<guest_id> } or just Set for "all selected per level"
const launching = ref(false)
const completingPlanetId = ref(null)
const changingPlanetId = ref(null)
const errorMessage = ref('')

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

/** Три группы по уровню экстрима. В каждой — заказы (гости в очереди, не в активной планете). */
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

function toggleGuest(level, guestId) {
  const key = `l${level}`
  if (!selectedGuestIds.value[key]) selectedGuestIds.value[key] = new Set()
  const set = selectedGuestIds.value[key]
  if (set.has(guestId)) set.delete(guestId)
  else set.add(guestId)
  selectedGuestIds.value = { ...selectedGuestIds.value }
}

function isSelected(level, guestId) {
  const set = selectedGuestIds.value[`l${level}`]
  return set?.has(guestId) ?? false
}

function selectAll(level, orders) {
  const set = new Set(orders.map((o) => o.guest?.id).filter(Boolean))
  selectedGuestIds.value = { ...selectedGuestIds.value, [`l${level}`]: set }
}

function selectedCount(level) {
  const set = selectedGuestIds.value[`l${level}`]
  return set?.size ?? 0
}

async function launchTask(level) {
  const set = selectedGuestIds.value[`l${level}`]
  const guestIds = set ? Array.from(set) : []
  if (guestIds.length === 0) {
    errorMessage.value = 'Выберите хотя бы одного участника'
    return
  }
  const group = queueByExtremenessLevel.value.find((g) => g.level === level)
  const guests = (group?.orders ?? [])
    .map((o) => o.guest)
    .filter((g) => g && guestIds.includes(g.id))
  if (guests.length === 0) {
    errorMessage.value = 'Выберите участников из списка'
    return
  }
  launching.value = true
  errorMessage.value = ''
  try {
    const task = await getRandomTamadaTaskByLevel(level)
    const taskText = task?.task_text ?? 'Выполните задание и сделайте фотоотчёт!'
    await createPlanetFromGuests(guests, taskText, level, task?.difficulty)
    selectedGuestIds.value = { ...selectedGuestIds.value, [`l${level}`]: new Set() }
    await loadAll()
  } catch (e) {
    errorMessage.value = e?.message || 'Ошибка запуска'
  } finally {
    launching.value = false
  }
}

async function acceptTask(planet) {
  if (completingPlanetId.value) return
  completingPlanetId.value = planet.id
  errorMessage.value = ''
  try {
    await completePlanet(planet.id)
    await loadAll()
  } catch (e) {
    errorMessage.value = e?.message || 'Ошибка'
  } finally {
    completingPlanetId.value = null
  }
}

async function changeTask(planet) {
  if (changingPlanetId.value) return
  const task = planet?.task
  const level = task ? difficultyToExtremenessLevel(task.difficulty) : 2
  changingPlanetId.value = planet.id
  errorMessage.value = ''
  try {
    const newTask = await getRandomTamadaTaskByLevel(level)
    const text = newTask?.task_text ?? 'Выполните задание и сделайте фотоотчёт!'
    const diff = newTask?.difficulty ?? (level === 1 ? 1 : level === 2 ? 3 : 5)
    await replacePlanetTask(planet.id, text, diff)
    await loadAll()
  } catch (e) {
    errorMessage.value = e?.message || 'Ошибка смены задания'
  } finally {
    changingPlanetId.value = null
  }
}

function planetDifficultyClass(planet) {
  const d = planet?.task?.difficulty ?? 3
  const map = {
    1: 'border-cantina-success/50',
    2: 'border-cantina-copper/50',
    3: 'border-cantina-amber/50',
    4: 'border-cantina-copper-light/50',
    5: 'border-cantina-danger/50',
  }
  return map[d] || map[3]
}

const unsub = subscribeOrders(loadAll)
onMounted(loadAll)
onUnmounted(unsub)
</script>

<template>
  <div class="min-h-screen bg-cantina-bg text-cantina-cream font-sans flex flex-col">
    <header class="flex-shrink-0 p-4 md:p-6 border-b border-cantina-border bg-cantina-surface">
      <div class="max-w-4xl mx-auto flex flex-wrap items-center gap-4">
        <router-link
          to="/admin"
          class="text-cantina-muted hover:text-cantina-copper transition-colors flex items-center gap-1"
        >
          <span class="material-icons text-lg">arrow_back</span>
          Штаб
        </router-link>
        <h1 class="font-display text-xl md:text-2xl font-semibold text-cantina-amber">Терминал тамады</h1>
      </div>
    </header>

    <div class="flex-1 max-w-4xl mx-auto w-full p-4 md:p-6 space-y-8">
      <p v-if="errorMessage" class="px-4 py-2 rounded-lg bg-cantina-danger/20 border border-cantina-danger/50 text-cantina-cream text-sm">
        {{ errorMessage }}
      </p>

      <!-- Ручной запуск: три планеты, выбор участников, кнопка Запустить -->
      <section>
        <h2 class="font-display text-lg font-semibold text-cantina-amber mb-3">Запуск задания</h2>
        <p class="text-cantina-muted text-sm mb-4">
          Выберите участников в кружке и нажмите «Запустить задание». Можно запустить даже для одного человека.
        </p>
        <div class="grid gap-6 md:grid-cols-3">
          <div
            v-for="group in queueByExtremenessLevel"
            :key="group.level"
            class="rounded-xl border-2 bg-cantina-card p-4"
            :class="{
              'border-cantina-success/50': group.level === 1,
              'border-cantina-copper/50': group.level === 2,
              'border-cantina-danger/50': group.level === 3,
            }"
          >
            <div
              class="font-display font-bold text-base mb-3"
              :class="{
                'text-cantina-success': group.level === 1,
                'text-cantina-copper': group.level === 2,
                'text-cantina-danger': group.level === 3,
              }"
            >
              {{ group.name }}
            </div>
            <div class="space-y-2 max-h-48 overflow-y-auto">
              <label
                v-for="order in group.orders"
                :key="order.id"
                class="flex items-center gap-2 cursor-pointer hover:bg-cantina-surface/50 rounded-lg px-2 py-1"
              >
                <input
                  type="checkbox"
                  :checked="isSelected(group.level, order.guest?.id)"
                  class="rounded accent-cantina-copper"
                  @change="toggleGuest(group.level, order.guest?.id)"
                />
                <div class="w-8 h-8 rounded-full bg-cantina-surface overflow-hidden flex-shrink-0 border border-cantina-border">
                  <img
                    v-if="order.guest?.avatar_url"
                    :src="order.guest.avatar_url"
                    :alt="order.callsign"
                    class="w-full h-full object-cover"
                  />
                  <div v-else class="w-full h-full flex items-center justify-center text-cantina-muted text-xs">
                    {{ (order.callsign || '?').slice(0, 1) }}
                  </div>
                </div>
                <span class="font-mono text-sm text-cantina-cream truncate">{{ order.callsign }}</span>
              </label>
            </div>
            <div class="mt-3 flex flex-wrap gap-2">
              <button
                v-if="group.orders.length"
                type="button"
                class="text-xs text-cantina-muted hover:text-cantina-copper transition-colors"
                @click="selectAll(group.level, group.orders)"
              >
                Выбрать всех ({{ group.orders.length }})
              </button>
              <button
                type="button"
                :disabled="launching || selectedCount(group.level) === 0"
                class="px-4 py-2 rounded-lg bg-cantina-copper hover:bg-cantina-copper-light disabled:opacity-50 text-cantina-bg font-mono font-bold text-sm uppercase tracking-wider transition-colors"
                @click="launchTask(group.level)"
              >
                {{ launching ? '…' : `Запустить (${selectedCount(group.level)})` }}
              </button>
            </div>
          </div>
        </div>
      </section>

      <!-- Активные планеты: принять задание, сменить задание -->
      <section>
        <h2 class="font-display text-lg font-semibold text-cantina-amber mb-3">Активные задания</h2>
        <p class="text-cantina-muted text-sm mb-4">
          Нажмите «Задание выполнено», когда участники выполнили задание (или приложили фото). Бариста увидит бейдж и начнёт готовить кофе.
        </p>
        <div v-if="activePlanets.length === 0" class="text-cantina-muted py-4">
          Нет активных планет.
        </div>
        <div v-else class="grid gap-4 md:grid-cols-2">
          <div
            v-for="planet in activePlanets"
            :key="planet.id"
            :class="['rounded-xl border-2 bg-cantina-card p-4', planetDifficultyClass(planet)]"
          >
            <div class="font-mono font-bold text-cantina-copper">{{ planet.name }}</div>
            <p v-if="planet.task" class="text-cantina-sand text-sm mt-1 line-clamp-3">
              {{ planet.task.task_text }}
            </p>
            <div v-if="planet.members?.length" class="flex flex-wrap gap-1.5 mt-2">
              <span
                v-for="m in planet.members"
                :key="m.id"
                class="text-cantina-muted text-xs font-mono"
              >
                {{ m.callsign }}
              </span>
            </div>
            <div class="mt-4 flex flex-wrap gap-2">
              <button
                type="button"
                :disabled="!!completingPlanetId"
                class="px-4 py-2 rounded-lg bg-cantina-success hover:opacity-90 disabled:opacity-50 text-white font-mono font-bold text-sm uppercase tracking-wider transition-colors"
                title="Отметить задание выполненным — на табло и у бариста появится бейдж"
                @click="acceptTask(planet)"
              >
                {{ completingPlanetId === planet.id ? '…' : 'Задание выполнено' }}
              </button>
              <button
                type="button"
                :disabled="!!changingPlanetId"
                class="px-4 py-2 rounded-lg border border-cantina-border text-cantina-sand hover:bg-cantina-surface disabled:opacity-50 font-mono text-sm transition-colors"
                title="Выдать новое задание того же уровня экстрима"
                @click="changeTask(planet)"
              >
                {{ changingPlanetId === planet.id ? '…' : 'Сменить задание' }}
              </button>
            </div>
          </div>
        </div>
      </section>

      <p class="text-cantina-muted text-sm">
        Участники могут <router-link to="/tamada" class="text-cantina-copper hover:underline">открыть страницу с телефона</router-link> и приложить фото к своей планете.
      </p>
    </div>
  </div>
</template>

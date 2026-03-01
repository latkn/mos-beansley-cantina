<script setup>
import { ref, computed, onMounted } from 'vue'
import { getAllGuests, getGuestById, updateGuest, deleteGuest } from '@/api/guests'
import { getOrdersWithDrinkProfileByGuestId, getOrdersByGuestId } from '@/api/orders'

const guests = ref([])
const loading = ref(true)
const searchQuery = ref('')
const selectedGuestId = ref(null)
const selectedGuest = ref(null)
const loadingDetail = ref(false)
const baristaNoteDraft = ref('')
const savingNote = ref(false)
const savingCallsign = ref(false)
const callsignDraft = ref('')
const isEditingCallsign = ref(false)
const guestOrdersWithProfile = ref([])
const guestOrdersList = ref([])
const deletingId = ref(null)
const deleteConfirmId = ref(null)

/** Цвета линий графика: сладость, горечь, интенсивность, экспериментальность */
const CHART_COLORS = {
  sweetness: '#eab308',
  bitterness: '#dc2626',
  intensity: '#b45309',
  extremeness: '#a855f7',
}

const filteredGuests = computed(() => {
  const q = (searchQuery.value || '').trim().toUpperCase()
  if (!q) return guests.value
  return guests.value.filter((g) => (g.callsign || '').toUpperCase().includes(q))
})

async function load() {
  loading.value = true
  try {
    guests.value = await getAllGuests()
  } catch (e) {
    console.error(e)
    guests.value = []
  } finally {
    loading.value = false
  }
}

async function openGuest(id) {
  selectedGuestId.value = id
  selectedGuest.value = null
  baristaNoteDraft.value = ''
  callsignDraft.value = ''
  isEditingCallsign.value = false
  guestOrdersWithProfile.value = []
  guestOrdersList.value = []
  loadingDetail.value = true
  try {
    const [guest, ordersForChart, ordersForList] = await Promise.all([
      getGuestById(id),
      getOrdersWithDrinkProfileByGuestId(id),
      getOrdersByGuestId(id),
    ])
    selectedGuest.value = guest
    baristaNoteDraft.value = guest?.barista_note ?? ''
    callsignDraft.value = guest?.callsign ?? ''
    guestOrdersWithProfile.value = ordersForChart
    guestOrdersList.value = ordersForList
  } catch (e) {
    console.error(e)
  } finally {
    loadingDetail.value = false
  }
}

function closeGuest() {
  selectedGuestId.value = null
  selectedGuest.value = null
  deleteConfirmId.value = null
}

async function saveBaristaNote() {
  if (!selectedGuest.value?.id || savingNote.value) return
  savingNote.value = true
  try {
    await updateGuest(selectedGuest.value.id, { barista_note: baristaNoteDraft.value.trim() || null })
    selectedGuest.value = { ...selectedGuest.value, barista_note: baristaNoteDraft.value.trim() || null }
    const idx = guests.value.findIndex((g) => g.id === selectedGuest.value.id)
    if (idx !== -1) guests.value[idx] = { ...guests.value[idx], barista_note: selectedGuest.value.barista_note }
  } catch (e) {
    alert(e?.message || 'Не удалось сохранить заметку')
  } finally {
    savingNote.value = false
  }
}

function startEditCallsign() {
  callsignDraft.value = selectedGuest.value?.callsign ?? ''
  isEditingCallsign.value = true
}

function cancelEditCallsign() {
  callsignDraft.value = selectedGuest.value?.callsign ?? ''
  isEditingCallsign.value = false
}

async function saveCallsign() {
  const trimmed = (callsignDraft.value || '').trim().toUpperCase()
  if (!selectedGuest.value?.id || savingCallsign.value || !trimmed) return
  if (trimmed === (selectedGuest.value.callsign || '').toUpperCase()) {
    isEditingCallsign.value = false
    return
  }
  savingCallsign.value = true
  try {
    await updateGuest(selectedGuest.value.id, { callsign: trimmed })
    selectedGuest.value = { ...selectedGuest.value, callsign: trimmed }
    const idx = guests.value.findIndex((g) => g.id === selectedGuest.value.id)
    if (idx !== -1) guests.value[idx] = { ...guests.value[idx], callsign: trimmed }
    isEditingCallsign.value = false
  } catch (e) {
    alert(e?.message || 'Не удалось сохранить имя (возможно, такой позывной уже есть)')
  } finally {
    savingCallsign.value = false
  }
}

function openDeleteConfirm(id, e) {
  e?.stopPropagation?.()
  deleteConfirmId.value = id
}

function cancelDelete() {
  deleteConfirmId.value = null
}

async function confirmDelete() {
  const id = deleteConfirmId.value
  if (!id) return
  deletingId.value = id
  try {
    await deleteGuest(id)
    guests.value = guests.value.filter((g) => g.id !== id)
    if (selectedGuestId.value === id) closeGuest()
    deleteConfirmId.value = null
  } catch (e) {
    alert(e?.message || 'Не удалось удалить гостя')
  } finally {
    deletingId.value = null
  }
}

function formatDate(iso) {
  if (!iso) return '—'
  const d = new Date(iso)
  return d.toLocaleString('ru-RU', { dateStyle: 'short', timeStyle: 'short' })
}

function profileVal(v) {
  const n = Number(v)
  return Number.isNaN(n) ? '—' : `${n}/10`
}

const orderStatusLabel = {
  pending: 'В очереди',
  ready: 'Готово',
  picked_up: 'Выдан',
}
function orderStatusText(status) {
  return orderStatusLabel[status] ?? status
}

/** Данные для графика: ось X — время (индексы заказов), Y — 0..10. Возвращает { points, width, height, padding, xScale, yScale } */
const chartConfig = computed(() => {
  const points = guestOrdersWithProfile.value
  const padding = { top: 12, right: 12, bottom: 28, left: 28 }
  const width = 320
  const height = 180
  const n = points.length
  if (n === 0) return { points: [], width, height, padding, xScale: () => 0, yScale: () => height - padding.bottom, series: [] }
  const xScale = (i) => padding.left + (i / Math.max(1, n - 1)) * (width - padding.left - padding.right)
  const yScale = (v) => padding.top + (1 - v / 10) * (height - padding.top - padding.bottom)
  const series = [
    { key: 'sweetness', label: 'Сладость', color: CHART_COLORS.sweetness, values: points.map((p) => p.sweetness) },
    { key: 'bitterness', label: 'Горечь', color: CHART_COLORS.bitterness, values: points.map((p) => p.bitterness) },
    { key: 'intensity', label: 'Интенсивность', color: CHART_COLORS.intensity, values: points.map((p) => p.intensity) },
    { key: 'extremeness', label: 'Экспериментальность', color: CHART_COLORS.extremeness, values: points.map((p) => p.extremeness) },
  ]
  return { points, width, height, padding, xScale, yScale, series }
})

function chartPath(values, xScale, yScale) {
  const n = values.length
  if (n === 0) return ''
  return values.map((v, i) => `${i === 0 ? 'M' : 'L'} ${xScale(i)} ${yScale(v)}`).join(' ')
}

onMounted(load)
</script>

<template>
  <div class="min-h-screen bg-cantina-bg text-cantina-cream p-4 md:p-6 font-sans">
    <div class="max-w-4xl mx-auto">
      <div class="flex items-center justify-between gap-4 mb-6 flex-wrap">
        <h1 class="font-display text-2xl text-cantina-amber">Участники</h1>
        <router-link to="/admin/edit" class="text-cantina-sand hover:text-cantina-cream text-sm transition-colors">← Админ</router-link>
      </div>

      <p class="text-cantina-muted text-sm mb-4">
        Список гостей: просмотр, заметка для бариста, удаление записи.
      </p>

      <div class="mb-4">
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Поиск по позывному..."
          class="w-full max-w-xs px-3 py-2 rounded-lg bg-cantina-surface border border-cantina-border text-cantina-cream placeholder:text-cantina-muted font-mono text-sm focus:ring-2 focus:ring-cantina-copper focus:border-transparent"
        />
      </div>

      <div v-if="loading" class="flex items-center gap-2 text-cantina-muted py-8">
        <span class="w-5 h-5 border-2 border-cantina-border border-t-cantina-copper rounded-full animate-spin" />
        Загрузка…
      </div>

      <div v-else class="space-y-2">
        <button
          v-for="g in filteredGuests"
          :key="g.id"
          type="button"
          class="w-full flex items-center gap-4 p-4 rounded-xl border-2 text-left transition-colors"
          :class="selectedGuestId === g.id ? 'bg-cantina-copper/15 border-cantina-copper' : 'bg-cantina-card border-cantina-border hover:border-cantina-copper/50'"
          @click="openGuest(g.id)"
        >
          <div class="w-12 h-12 rounded-full bg-cantina-surface overflow-hidden flex-shrink-0 border border-cantina-border">
            <img v-if="g.avatar_url" :src="g.avatar_url" :alt="g.callsign" class="w-full h-full object-cover" />
            <div v-else class="w-full h-full flex items-center justify-center text-cantina-muted font-bold">{{ (g.callsign || '?').slice(0, 2) }}</div>
          </div>
          <div class="min-w-0 flex-1">
            <span class="font-mono font-bold text-cantina-cream">{{ g.callsign }}</span>
            <span v-if="g.race?.name" class="text-cantina-muted text-sm ml-2">· {{ g.race.name }}</span>
          </div>
          <span class="text-cantina-muted text-xs flex-shrink-0">{{ formatDate(g.created_at) }}</span>
          <span v-if="g.barista_note" class="material-icons text-cantina-amber text-lg flex-shrink-0" title="Есть заметка бариста">note</span>
        </button>
        <p v-if="!filteredGuests.length" class="text-cantina-muted py-8">Нет участников.</p>
      </div>
    </div>

    <!-- Детальная панель гостя (модалка) -->
    <Teleport to="body">
      <div
        v-if="selectedGuestId"
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60"
        @click.self="closeGuest"
      >
        <div class="bg-cantina-card border-2 border-cantina-copper rounded-xl max-w-lg w-full max-h-[90vh] overflow-hidden shadow-cantina flex flex-col">
          <div class="p-4 border-b border-cantina-border flex items-center justify-between flex-shrink-0">
            <h2 class="font-display text-lg font-semibold text-cantina-amber">Карточка гостя</h2>
            <button type="button" class="text-cantina-muted hover:text-cantina-cream p-1" @click="closeGuest">
              <span class="material-icons">close</span>
            </button>
          </div>
          <div class="p-4 overflow-y-auto flex-1 min-h-0">
            <template v-if="loadingDetail">
              <div class="flex items-center gap-2 text-cantina-muted py-8">
                <span class="w-5 h-5 border-2 border-cantina-border border-t-cantina-copper rounded-full animate-spin" />
                Загрузка…
              </div>
            </template>
            <template v-else-if="selectedGuest">
              <div class="flex items-center gap-4 mb-6">
                <div class="w-20 h-20 rounded-full bg-cantina-surface overflow-hidden flex-shrink-0 border border-cantina-border">
                  <img v-if="selectedGuest.avatar_url" :src="selectedGuest.avatar_url" :alt="selectedGuest.callsign" class="w-full h-full object-cover" />
                  <div v-else class="w-full h-full flex items-center justify-center text-cantina-muted font-bold text-2xl">{{ (selectedGuest.callsign || '?').slice(0, 2) }}</div>
                </div>
                <div class="min-w-0 flex-1">
                  <div v-if="!isEditingCallsign" class="flex items-center gap-2 flex-wrap">
                    <span class="font-mono font-bold text-xl text-cantina-cream">{{ selectedGuest.callsign }}</span>
                    <button type="button" class="text-cantina-muted hover:text-cantina-copper text-xs underline" @click="startEditCallsign">Изменить</button>
                  </div>
                  <div v-else class="flex flex-wrap items-center gap-2">
                    <input
                      v-model="callsignDraft"
                      type="text"
                      class="px-2 py-1 rounded bg-cantina-surface border border-cantina-border text-cantina-cream font-mono text-lg w-40 focus:ring-2 focus:ring-cantina-copper"
                      placeholder="Позывной"
                      @keydown.enter="saveCallsign"
                      @keydown.escape="cancelEditCallsign"
                    />
                    <button type="button" :disabled="savingCallsign" class="px-2 py-1 rounded bg-cantina-copper text-cantina-bg text-sm font-mono disabled:opacity-50" @click="saveCallsign">{{ savingCallsign ? '…' : 'Сохранить' }}</button>
                    <button type="button" class="text-cantina-muted text-sm" @click="cancelEditCallsign">Отмена</button>
                  </div>
                  <div v-if="selectedGuest.race?.name" class="text-cantina-amber">{{ selectedGuest.race.name }}</div>
                  <div class="text-cantina-muted text-sm mt-1">{{ formatDate(selectedGuest.created_at) }}</div>
                </div>
              </div>

              <!-- График профиля напитков по заказам (время → интенсивность параметров) -->
              <div v-if="chartConfig.points.length > 0" class="mt-6 pt-4 border-t border-cantina-border">
                <div class="text-cantina-muted uppercase tracking-wider text-xs mb-2">Профиль заказанных напитков по времени</div>
                <p class="text-cantina-sand text-xs mb-2">Каждая точка — одна чашка. По горизонтали: порядок заказов (время). По вертикали: значение 0–10.</p>
                <div class="flex flex-col sm:flex-row gap-3 items-start">
                  <svg :viewBox="`0 0 ${chartConfig.width} ${chartConfig.height}`" class="w-full max-w-[320px] h-[180px] flex-shrink-0" preserveAspectRatio="xMidYMid meet">
                    <!-- Сетка Y (0, 5, 10) -->
                    <line :x1="chartConfig.padding.left" :y1="chartConfig.yScale(0)" :x2="chartConfig.width - chartConfig.padding.right" :y2="chartConfig.yScale(0)" stroke="currentColor" stroke-opacity="0.15" stroke-dasharray="2 2" />
                    <line :x1="chartConfig.padding.left" :y1="chartConfig.yScale(5)" :x2="chartConfig.width - chartConfig.padding.right" :y2="chartConfig.yScale(5)" stroke="currentColor" stroke-opacity="0.15" stroke-dasharray="2 2" />
                    <line :x1="chartConfig.padding.left" :y1="chartConfig.yScale(10)" :x2="chartConfig.width - chartConfig.padding.right" :y2="chartConfig.yScale(10)" stroke="currentColor" stroke-opacity="0.15" stroke-dasharray="2 2" />
                    <!-- Линии по параметрам -->
                    <g v-for="s in chartConfig.series" :key="s.key">
                      <path
                        :d="chartPath(s.values, chartConfig.xScale, chartConfig.yScale)"
                        :stroke="s.color"
                        stroke-width="2"
                        fill="none"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                      />
                    </g>
                    <!-- Подписи оси Y -->
                    <text :x="chartConfig.padding.left - 6" :y="chartConfig.yScale(0) + 4" class="text-[10px] fill-current text-cantina-muted" text-anchor="end">0</text>
                    <text :x="chartConfig.padding.left - 6" :y="chartConfig.yScale(10) + 4" class="text-[10px] fill-current text-cantina-muted" text-anchor="end">10</text>
                  </svg>
                  <div class="flex flex-wrap gap-x-4 gap-y-1 text-xs">
                    <span v-for="s in chartConfig.series" :key="s.key" class="flex items-center gap-1.5">
                      <span class="w-3 h-0.5 rounded-full flex-shrink-0" :style="{ backgroundColor: s.color }" />
                      {{ s.label }}
                    </span>
                  </div>
                </div>
              </div>
              <div v-else-if="selectedGuestId" class="mt-6 pt-4 border-t border-cantina-border">
                <p class="text-cantina-muted text-sm">Нет заказов — график появится после первых чашек.</p>
              </div>

              <div class="space-y-4 text-sm">
                <div>
                  <span class="text-cantina-muted uppercase tracking-wider">Профиль напитка</span>
                  <div class="mt-1 grid grid-cols-2 gap-2">
                    <div>Сладость: {{ profileVal(selectedGuest.sweetness) }}</div>
                    <div>Горечь: {{ profileVal(selectedGuest.bitterness) }}</div>
                    <div>Интенсивность: {{ profileVal(selectedGuest.intensity) }}</div>
                    <div>Экспериментальность: {{ profileVal(selectedGuest.extremeness) }}</div>
                  </div>
                </div>
                <div v-if="selectedGuest.allergies?.length">
                  <span class="text-cantina-muted uppercase tracking-wider">Аллергии</span>
                  <p class="mt-1 text-cantina-cream">{{ Array.isArray(selectedGuest.allergies) ? selectedGuest.allergies.join(', ') : selectedGuest.allergies }}</p>
                </div>
              </div>

              <!-- Список заказов -->
              <div class="mt-6 pt-4 border-t border-cantina-border">
                <span class="text-cantina-muted uppercase tracking-wider text-xs">Заказы</span>
                <ul v-if="guestOrdersList.length" class="mt-2 space-y-1.5 max-h-40 overflow-y-auto">
                  <li
                    v-for="order in guestOrdersList"
                    :key="order.id"
                    class="flex flex-wrap items-center gap-2 py-1.5 px-2 rounded-lg bg-cantina-surface/50 text-sm"
                  >
                    <span class="text-cantina-muted font-mono text-xs shrink-0">{{ formatDate(order.created_at) }}</span>
                    <span class="text-cantina-cream font-mono">{{ order.coffee_name }}</span>
                    <span
                      class="ml-auto text-xs px-2 py-0.5 rounded"
                      :class="{
                        'bg-cantina-amber/20 text-cantina-amber': order.status === 'pending',
                        'bg-cantina-success/20 text-cantina-success': order.status === 'ready',
                        'text-cantina-muted': order.status === 'picked_up',
                      }"
                    >
                      {{ orderStatusText(order.status) }}
                    </span>
                  </li>
                </ul>
                <p v-else class="mt-2 text-cantina-muted text-sm">Нет заказов.</p>
              </div>

              <div class="mt-6 pt-4 border-t border-cantina-border">
                <label class="block text-cantina-muted uppercase tracking-wider text-xs mb-2">Заметка бариста (видна только баристе)</label>
                <textarea
                  v-model="baristaNoteDraft"
                  rows="3"
                  placeholder="Например: предпочитает без сахара, любит крепкий..."
                  class="w-full px-3 py-2 rounded-lg bg-cantina-surface border border-cantina-border text-cantina-cream placeholder:text-cantina-muted text-sm focus:ring-2 focus:ring-cantina-copper resize-y"
                />
                <button
                  type="button"
                  :disabled="savingNote"
                  class="mt-2 px-4 py-2 rounded-lg bg-cantina-copper hover:bg-cantina-copper-light text-cantina-bg font-mono text-sm font-bold disabled:opacity-50"
                  @click="saveBaristaNote"
                >
                  {{ savingNote ? '…' : 'Сохранить заметку' }}
                </button>
              </div>

              <div class="mt-6 pt-4 border-t border-cantina-border flex justify-end">
                <button
                  type="button"
                  class="px-4 py-2 rounded-lg border border-cantina-danger text-cantina-danger hover:bg-cantina-danger/20 transition-colors text-sm font-mono"
                  :disabled="!!deletingId"
                  @click="openDeleteConfirm(selectedGuest.id, $event)"
                >
                  Удалить гостя
                </button>
              </div>
            </template>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Подтверждение удаления -->
    <Teleport to="body">
      <div
        v-if="deleteConfirmId"
        class="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/70"
        @click.self="cancelDelete"
      >
        <div class="bg-cantina-card border-2 border-cantina-danger rounded-xl p-6 max-w-sm w-full shadow-cantina">
          <h3 class="font-display text-lg font-semibold text-cantina-amber mb-2">Удалить гостя?</h3>
          <p class="text-cantina-sand text-sm mb-4">
            Будут удалены запись гостя и все связанные заказы и данные. Это нельзя отменить.
          </p>
          <div class="flex gap-2">
            <button
              type="button"
              class="flex-1 py-2 rounded-lg bg-cantina-danger hover:opacity-90 text-white font-semibold disabled:opacity-50"
              :disabled="!!deletingId"
              @click="confirmDelete"
            >
              {{ deletingId ? '…' : 'Удалить' }}
            </button>
            <button
              type="button"
              class="px-4 py-2 rounded-lg border border-cantina-border text-cantina-sand hover:bg-cantina-surface"
              @click="cancelDelete"
            >
              Отмена
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

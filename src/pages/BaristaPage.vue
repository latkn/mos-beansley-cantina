<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import {
  getPendingOrders,
  markOrderReady,
  markOrderPickedUp,
  updateOrderCoffee,
  subscribeOrders,
  getGuestTriedCoffeeIds,
} from '@/api/orders'
import { getRecommendedCoffeesWithScores } from '@/api/coffee'
import { getGuestIdsWithCompletedTask } from '@/api/planets'

const preparing = ref([])
const guestIdsTaskCompleted = ref(new Set())
const loading = ref(true)
const actionId = ref(null)
/** id заказов, которые «в работе» — раскрыты в большую карточку с инструкцией */
const expandedOrderIds = ref([])
const errorMessage = ref('')
/** Топ-3 напитка с процентом совпадения по заказу: orderId -> { loading, items: [{ drink, matchPercent }] } */
const orderDrinkOptions = ref({})
/** ID напитков, которые гость уже пробовал ранее (orderId -> number[]) */
const guestTriedCoffeeIdsByOrder = ref({})
/** Какой напиток бариста смотрит (клик по карточке): orderId -> drink. Закрепление — только по кнопке «Выбрать». */
const previewDrinkByOrder = ref({})

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    const [pending, taskCompletedIds] = await Promise.all([
      getPendingOrders(),
      getGuestIdsWithCompletedTask(),
    ])
    preparing.value = pending
    guestIdsTaskCompleted.value = taskCompletedIds
    expandedOrderIds.value = expandedOrderIds.value.filter((id) => pending.some((o) => o.id === id))
    orderDrinkOptions.value = {}
    guestTriedCoffeeIdsByOrder.value = {}
    previewDrinkByOrder.value = {}
  } finally {
    loading.value = false
  }
}

/** Вызов гостя (звук/табло — позже) */
function callGuest(order) {
  // TODO: воспроизвести звук, отправить на табло «Вызов: ПОЗЫВНОЙ»
  console.info('Вызов гостя:', order.callsign)
}

async function setExpanded(orderId, value) {
  if (value) {
    if (!expandedOrderIds.value.includes(orderId)) expandedOrderIds.value = [...expandedOrderIds.value, orderId]
    const order = preparing.value.find((o) => o.id === orderId)
    if (order && !orderDrinkOptions.value[orderId]) {
      orderDrinkOptions.value[orderId] = { loading: true, items: [] }
      const guestId = order.guest?.id
      try {
        const [items, triedIds] = await Promise.all([
          getRecommendedCoffeesWithScores(order.guest ?? {}, order.allergies ?? [], 3),
          guestId ? getGuestTriedCoffeeIds(guestId, orderId) : Promise.resolve([]),
        ])
        orderDrinkOptions.value[orderId] = { loading: false, items }
        guestTriedCoffeeIdsByOrder.value = { ...guestTriedCoffeeIdsByOrder.value, [orderId]: triedIds }
      } catch (e) {
        console.error(e)
        orderDrinkOptions.value[orderId] = { loading: false, items: [] }
        guestTriedCoffeeIdsByOrder.value = { ...guestTriedCoffeeIdsByOrder.value, [orderId]: [] }
      }
    }
  } else {
    expandedOrderIds.value = expandedOrderIds.value.filter((id) => id !== orderId)
  }
}

function isExpanded(orderId) {
  return expandedOrderIds.value.includes(orderId)
}

function getDrinkOptions(orderId) {
  return orderDrinkOptions.value[orderId] ?? { loading: false, items: [] }
}

/** Гость уже пробовал этот напиток в прошлых заказах (не в текущем). */
function isDrinkTriedByGuest(orderId, coffeeId) {
  if (!coffeeId) return false
  const ids = guestTriedCoffeeIdsByOrder.value[orderId]
  return Array.isArray(ids) && ids.includes(coffeeId)
}

function hasGuestProfile(order) {
  const g = order?.guest
  if (!g) return false
  const v = (key) => g[key]
  return [v('sweetness'), v('bitterness'), v('intensity'), v('extremeness')].some(
    (n) => n != null && n !== '' && !Number.isNaN(Number(n))
  )
}

function profileParam(order, key) {
  const n = Number(order?.guest?.[key])
  return Number.isNaN(n) ? 5 : Math.min(10, Math.max(0, Math.round(n)))
}

function profilePercent(order, key) {
  return profileParam(order, key) * 10
}

/** Клик по карточке напитка — только показать состав и инструкцию (просмотр). */
function setPreviewDrink(orderId, drink) {
  previewDrinkByOrder.value = { ...previewDrinkByOrder.value, [orderId]: drink }
}

function getPreviewDrink(orderId) {
  return previewDrinkByOrder.value[orderId] ?? null
}

/** Закрепить за заказом выбранный напиток (после просмотра нажать «Выбрать»). */
async function selectDrink(order, item) {
  const drink = item?.drink ?? item
  if (!drink?.id) return
  if (actionId.value) return
  actionId.value = order.id
  errorMessage.value = ''
  try {
    await updateOrderCoffee(order.id, drink.id, drink.name)
    const idx = preparing.value.findIndex((o) => o.id === order.id)
    if (idx !== -1) {
      preparing.value[idx] = { ...preparing.value[idx], coffee_id: drink.id, coffee_name: drink.name }
    }
    setPreviewDrink(order.id, null)
  } catch (e) {
    console.error(e)
    errorMessage.value = e?.message || 'Не удалось сменить напиток'
  } finally {
    actionId.value = null
  }
}

/** Готовить → карточка становится большой. Готово → вызов гостя + в табло. */
async function handleStartPreparing(order) {
  setExpanded(order.id, true)
}

async function handleReady(order) {
  if (actionId.value) return
  actionId.value = order.id
  errorMessage.value = ''
  try {
    callGuest(order)
    await markOrderReady(order.id)
    await markOrderPickedUp(order.id)
    playOrderReadySound()
    await load()
  } catch (e) {
    console.error(e)
    errorMessage.value = e?.message || 'Не удалось отметить заказ'
  } finally {
    actionId.value = null
  }
}

const ORDER_READY_SOUND_URL = '/sound-on-the-trumpet.mp3'

function playOrderReadySound() {
  try {
    const audio = new Audio(ORDER_READY_SOUND_URL)
    audio.play().catch(() => {})
  } catch (_) {}
}

function isActionLoading(orderId) {
  return actionId.value === orderId
}

function hasTaskCompleted(order) {
  return order?.guest_id && guestIdsTaskCompleted.value.has(order.guest_id)
}

let taskCompletedPollInterval = null
const unsub = subscribeOrders(load)
onMounted(() => {
  load()
  taskCompletedPollInterval = setInterval(async () => {
    guestIdsTaskCompleted.value = await getGuestIdsWithCompletedTask()
  }, 5000)
})
onUnmounted(() => {
  unsub()
  if (taskCompletedPollInterval) clearInterval(taskCompletedPollInterval)
})
</script>

<template>
  <div class="min-h-screen bg-cantina-bg text-cantina-cream p-4 md:p-6 font-sans">
    <div class="max-w-4xl mx-auto">
      <h1 class="font-display text-2xl text-cantina-amber font-semibold mb-1">Бариста — очередь</h1>
      <p class="text-cantina-muted text-sm mb-6">
        Нажми «Готовить» на карточке — она станет большой с инструкцией. Потом «Готово» — вызов гостя, заказ сразу исчезнет из очереди. Работать могут двое и больше.
      </p>

      <p v-if="errorMessage" class="mb-4 px-4 py-2 rounded-lg bg-cantina-danger/20 border border-cantina-danger/50 text-cantina-cream text-sm">
        {{ errorMessage }}
      </p>

      <div v-if="loading && !preparing.length" class="flex flex-col items-center gap-3 py-12">
        <div class="w-10 h-10 border-2 border-cantina-border border-t-cantina-copper rounded-full animate-spin" />
        <span class="text-cantina-muted text-sm">Загрузка…</span>
      </div>

      <template v-else>
        <!-- Очередь: у каждой карточки кнопка Готовить → раскрывается большая, потом Готово -->
        <section v-if="preparing.length" class="mb-8">
          <h2 class="text-sm font-bold text-cantina-copper uppercase tracking-wider mb-3">Очередь заказов</h2>
          <ul class="space-y-4">
            <li
              v-for="(order, index) in preparing"
              :key="order.id"
              class="rounded-xl border-2 bg-cantina-card overflow-hidden"
              :class="isExpanded(order.id) ? 'border-cantina-copper/60 p-6 md:p-8' : 'border-cantina-border p-4 md:p-5'"
            >
              <!-- Малая карточка: номер, фото, позывной, напиток, кнопка Готовить -->
              <template v-if="!isExpanded(order.id)">
                <div class="flex flex-wrap items-center gap-4">
                  <span class="flex-shrink-0 w-12 h-12 rounded-xl bg-cantina-copper/30 text-cantina-cream flex items-center justify-center text-xl font-black">
                    №{{ index + 1 }}
                  </span>
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
                  <div class="min-w-0 flex-1">
                    <div class="font-mono font-bold text-cantina-cream uppercase tracking-wider text-lg">{{ order.callsign }}</div>
                    <div class="text-cantina-sand text-base">{{ order.coffee_name }}</div>
                    <span
                      v-if="hasTaskCompleted(order)"
                      class="inline-flex items-center gap-1 mt-1 px-2 py-0.5 rounded text-xs font-bold uppercase tracking-wider bg-cantina-success/30 text-cantina-success border border-cantina-success/50"
                    >
                      <span class="material-icons text-sm">task_alt</span>
                      Задание выполнено
                    </span>
                  </div>
                  <button
                    type="button"
                    :disabled="!!actionId"
                    class="btn-cantina-primary px-6 py-3 rounded-xl font-mono font-bold uppercase tracking-wider inline-flex items-center gap-2 disabled:opacity-60"
                    title="Готовить"
                    @click="handleStartPreparing(order)"
                  >
                    <span class="material-icons text-2xl">local_cafe</span>
                    <span>Готовить</span>
                  </button>
                </div>
              </template>

              <!-- Большая карточка: всё видно, кнопка Готово -->
              <template v-else>
                <div class="relative">
                  <div class="absolute top-0 right-0 flex items-center justify-center w-14 h-14 md:w-16 md:h-16 rounded-xl bg-cantina-copper text-cantina-ink font-black text-2xl md:text-3xl">
                    №{{ index + 1 }}
                  </div>
                  <div class="flex flex-wrap items-start gap-6 pr-20">
                    <div class="w-20 h-20 rounded-full bg-cantina-surface overflow-hidden flex-shrink-0 border border-cantina-border">
                      <img
                        v-if="order.guest?.avatar_url"
                        :src="order.guest.avatar_url"
                        :alt="order.callsign"
                        class="w-full h-full object-cover"
                      />
                      <div v-else class="w-full h-full flex items-center justify-center text-cantina-muted font-bold text-2xl">
                        {{ (order.callsign || '?').slice(0, 2) }}
                      </div>
                    </div>
                    <div class="min-w-0 flex-1 flex items-center gap-4">
                      <div class="w-16 h-16 rounded-xl bg-cantina-surface border border-cantina-border overflow-hidden flex-shrink-0">
                        <img
                          v-if="order.image_url"
                          :src="order.image_url"
                          :alt="order.coffee_name"
                          class="w-full h-full object-cover"
                        />
                        <div v-else class="w-full h-full flex items-center justify-center text-cantina-muted">
                          <span class="material-icons text-3xl">local_cafe</span>
                        </div>
                      </div>
                      <div>
                        <div class="font-mono font-bold text-cantina-cream uppercase tracking-wider text-2xl md:text-3xl">{{ order.callsign }}</div>
                        <div class="text-cantina-amber text-xl md:text-2xl mt-1">{{ order.coffee_name }}</div>
                        <span
                          v-if="hasTaskCompleted(order)"
                          class="inline-flex items-center gap-1 mt-2 px-3 py-1 rounded-lg text-sm font-bold uppercase tracking-wider bg-cantina-success/30 text-cantina-success border border-cantina-success/50"
                        >
                          <span class="material-icons text-base">task_alt</span>
                          Задание выполнено
                        </span>
                      </div>
                    </div>
                    <div class="flex-shrink-0">
                      <button
                        type="button"
                        :disabled="!!actionId"
                        class="px-8 py-4 rounded-xl bg-cantina-success hover:opacity-90 disabled:opacity-60 text-white font-mono text-lg font-bold uppercase tracking-wider flex items-center justify-center gap-2 min-w-[180px]"
                        :title="isActionLoading(order.id) ? 'Вызов…' : 'Готово — вызвать гостя'"
                        @click="handleReady(order)"
                      >
                        <span v-if="isActionLoading(order.id)" class="material-icons animate-spin text-2xl">hourglass_empty</span>
                        <span v-else class="material-icons text-2xl">done</span>
                        <span>{{ isActionLoading(order.id) ? 'Вызов…' : 'Готово' }}</span>
                      </button>
                    </div>
                  </div>
                  <div class="mt-6 p-4 rounded-xl bg-cantina-surface border border-cantina-border">
                    <div class="text-cantina-muted font-bold text-sm uppercase tracking-wider mb-3">Профиль гостя</div>
                    <template v-if="hasGuestProfile(order)">
                      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div>
                          <div class="flex justify-between text-xs text-cantina-muted mb-1">
                            <span>Сладость</span>
                            <span class="font-mono">{{ profileParam(order, 'sweetness') }}/10</span>
                          </div>
                          <div class="h-2 rounded-full bg-cantina-surface overflow-hidden">
                            <div class="h-full rounded-full bg-cantina-amber/80 transition-all" :style="{ width: profilePercent(order, 'sweetness') + '%' }" />
                          </div>
                        </div>
                        <div>
                          <div class="flex justify-between text-xs text-cantina-muted mb-1">
                            <span>Горечь</span>
                            <span class="font-mono">{{ profileParam(order, 'bitterness') }}/10</span>
                          </div>
                          <div class="h-2 rounded-full bg-cantina-surface overflow-hidden">
                            <div class="h-full rounded-full bg-cantina-danger/80 transition-all" :style="{ width: profilePercent(order, 'bitterness') + '%' }" />
                          </div>
                        </div>
                        <div>
                          <div class="flex justify-between text-xs text-cantina-muted mb-1">
                            <span>Интенсивность</span>
                            <span class="font-mono">{{ profileParam(order, 'intensity') }}/10</span>
                          </div>
                          <div class="h-2 rounded-full bg-cantina-surface overflow-hidden">
                            <div class="h-full rounded-full bg-cantina-copper/80 transition-all" :style="{ width: profilePercent(order, 'intensity') + '%' }" />
                          </div>
                        </div>
                        <div>
                          <div class="flex justify-between text-xs text-cantina-muted mb-1">
                            <span>Экспериментальность</span>
                            <span class="font-mono">{{ profileParam(order, 'extremeness') }}/10</span>
                          </div>
                          <div class="h-2 rounded-full bg-cantina-surface overflow-hidden">
                            <div class="h-full rounded-full bg-cantina-copper-light/80 transition-all" :style="{ width: profilePercent(order, 'extremeness') + '%' }" />
                          </div>
                        </div>
                      </div>
                    </template>
                    <p v-else class="text-cantina-muted text-sm">Гость не проходил квиз — профиль по умолчанию.</p>
                  </div>
                  <div v-if="order.allergies?.length" class="mt-6 p-4 rounded-xl bg-cantina-amber/15 border-2 border-cantina-amber/60">
                    <div class="text-cantina-amber font-bold text-sm uppercase tracking-wider mb-2">Аллергия у гостя</div>
                    <p class="text-xl text-cantina-cream font-mono">{{ order.allergies.join(', ') }}</p>
                  </div>
                  <div v-if="order.guest?.barista_note" class="mt-6 p-4 rounded-xl bg-cantina-copper/15 border border-cantina-copper/50">
                    <div class="text-cantina-copper font-bold text-sm uppercase tracking-wider mb-2">Заметка о госте</div>
                    <p class="text-cantina-cream whitespace-pre-wrap">{{ order.guest.barista_note }}</p>
                  </div>
                  <div class="mt-6">
                    <div class="text-cantina-muted font-bold text-sm uppercase tracking-wider mb-3">Выбор напитка (3 наиболее подходящих)</div>
                    <p class="text-cantina-muted text-xs mb-2">Нажми на карточку — посмотри состав и инструкцию. Потом нажми «Выбрать» у нужного напитка.</p>
                    <div v-if="getDrinkOptions(order.id).loading" class="flex items-center gap-2 text-cantina-muted">
                      <span class="w-5 h-5 border-2 border-cantina-border border-t-cantina-copper rounded-full animate-spin" />
                      Подбор напитков…
                    </div>
                    <div v-else class="grid grid-cols-1 sm:grid-cols-3 gap-3">
                      <div
                        v-for="opt in getDrinkOptions(order.id).items"
                        :key="opt.drink?.id"
                        class="rounded-xl border-2 transition-colors flex flex-col overflow-hidden"
                        :class="getPreviewDrink(order.id)?.id === opt.drink?.id
                          ? 'bg-cantina-copper/20 border-cantina-copper'
                          : order.coffee_id === opt.drink?.id
                            ? 'bg-cantina-success/10 border-cantina-success/60'
                            : 'bg-cantina-surface border-cantina-border hover:border-cantina-copper/50'"
                      >
                        <button
                          type="button"
                          class="text-left p-4 flex-1 flex items-start gap-3"
                          @click="setPreviewDrink(order.id, opt.drink)"
                        >
                          <div class="w-14 h-14 rounded-lg bg-cantina-bg border border-cantina-border overflow-hidden flex-shrink-0">
                            <img
                              v-if="opt.drink?.image_url"
                              :src="opt.drink.image_url"
                              :alt="opt.drink?.name"
                              class="w-full h-full object-cover"
                            />
                            <div v-else class="w-full h-full flex items-center justify-center text-cantina-muted">
                              <span class="material-icons text-2xl">local_cafe</span>
                            </div>
                          </div>
                          <div class="min-w-0 flex-1">
                            <div class="font-mono font-bold text-base text-cantina-cream flex flex-wrap items-center gap-2">
                              {{ opt.drink?.name ?? '—' }}
                              <span
                                v-if="isDrinkTriedByGuest(order.id, opt.drink?.id)"
                                class="inline-flex items-center px-2 py-0.5 rounded text-xs font-bold uppercase tracking-wider bg-cantina-copper/40 text-cantina-cream border border-cantina-copper/60"
                                title="Гость уже пробовал этот напиток в прошлых визитах — можно предложить другой"
                              >
                                Пробовал ранее
                              </span>
                            </div>
                            <div class="mt-1 text-sm" :class="order.coffee_id === opt.drink?.id ? 'text-cantina-success' : 'text-cantina-muted'">
                              {{ opt.matchPercent != null ? `Совпадение: ${opt.matchPercent}%` : '—' }}
                            </div>
                            <div v-if="order.coffee_id === opt.drink?.id" class="mt-1 text-xs text-cantina-success">Закреплён за заказом</div>
                          </div>
                        </button>
                        <div class="p-2 border-t border-cantina-border/50">
                          <button
                            type="button"
                            class="w-full py-2 rounded-lg text-sm font-mono font-bold uppercase transition-colors disabled:opacity-50"
                            :class="order.coffee_id === opt.drink?.id
                              ? 'bg-cantina-surface text-cantina-muted cursor-default'
                              : 'btn-cantina-primary'"
                            :disabled="!!actionId || order.coffee_id === opt.drink?.id"
                            title="Закрепить этот напиток за заказом"
                            @click.stop="selectDrink(order, opt)"
                          >
                            <span v-if="order.coffee_id !== opt.drink?.id" class="material-icons text-sm align-middle mr-1">check_circle</span>
                            {{ order.coffee_id === opt.drink?.id ? 'Выбран' : 'Выбрать' }}
                          </button>
                        </div>
                      </div>
                    </div>
                    <div
                      v-if="getPreviewDrink(order.id) && !getDrinkOptions(order.id).loading"
                      class="mt-4 p-4 rounded-xl bg-cantina-surface border border-cantina-border"
                    >
                      <div class="text-cantina-copper font-mono font-bold mb-2">{{ getPreviewDrink(order.id).name }} — просмотр</div>
                      <div v-if="(getPreviewDrink(order.id).ingredients || []).length">
                        <span class="text-cantina-muted text-xs uppercase">Ингредиенты:</span>
                        <p class="text-cantina-cream mt-0.5">{{ (getPreviewDrink(order.id).ingredients || []).join(', ') }}</p>
                      </div>
                      <p v-else class="text-cantina-muted text-sm">Нет состава.</p>
                    </div>
                  </div>
                </div>
              </template>
            </li>
          </ul>
        </section>

        <p v-if="!preparing.length" class="text-cantina-muted py-8 text-center">Очередь пуста.</p>
      </template>
    </div>
  </div>
</template>

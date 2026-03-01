<script setup>
import { ref } from 'vue'
import { createOrder } from '@/api/orders'

const props = defineProps({
  items: { type: Array, default: () => [] },
  guestId: { type: String, default: null },
})

const orderingId = ref(null)
const message = ref(null)

async function orderCoffee(coffee) {
  if (!props.guestId) return
  orderingId.value = coffee.id
  message.value = null
  try {
    await createOrder(props.guestId, coffee)
    message.value = `Заказ «${coffee.name}» принят. Смотри табло — когда будет готово.`
  } catch (e) {
    message.value = e?.message || 'Не удалось оформить заказ'
  } finally {
    orderingId.value = null
  }
}
</script>

<template>
  <div class="space-y-2">
    <h3 class="text-sm font-mono text-cyan-300">Рекомендованный протокол топлива</h3>
    <ul class="space-y-2">
      <li
        v-for="coffee in items"
        :key="coffee.id"
        class="font-mono text-slate-300 text-sm py-1 border-l-2 border-cyan-500/50 pl-2 flex flex-wrap items-center gap-2"
      >
        <span>
          {{ coffee.name }}
          <span v-if="coffee.description" class="text-slate-500">— {{ coffee.description }}</span>
        </span>
        <button
          v-if="guestId"
          type="button"
          :disabled="!!orderingId"
          class="text-xs px-2 py-1 rounded bg-amber-600/80 hover:bg-amber-500 text-white disabled:opacity-50"
          @click="orderCoffee(coffee)"
        >
          {{ orderingId === coffee.id ? '…' : 'Заказать' }}
        </button>
      </li>
    </ul>
    <p v-if="message" class="text-sm mt-2" :class="message.includes('принят') ? 'text-emerald-400' : 'text-amber-400'">
      {{ message }}
    </p>
  </div>
</template>

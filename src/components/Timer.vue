<script setup>
import { ref, onMounted, onUnmounted, watch } from 'vue'

const props = defineProps({
  seconds: { type: Number, default: 60 },
  running: { type: Boolean, default: true },
})
const emit = defineEmits(['finish'])

const left = ref(props.seconds)
let interval = null

function tick() {
  if (left.value <= 0) {
    if (interval) clearInterval(interval)
    emit('finish')
    return
  }
  left.value--
}

watch(
  () => props.seconds,
  (v) => { left.value = v },
  { immediate: true }
)
watch(
  () => props.running,
  (running) => {
    if (interval) clearInterval(interval)
    if (running) interval = setInterval(tick, 1000)
  },
  { immediate: true }
)

onUnmounted(() => {
  if (interval) clearInterval(interval)
})
onMounted(() => {
  if (props.running) interval = setInterval(tick, 1000)
})
</script>

<template>
  <div class="font-mono text-4xl tabular-nums text-cyan-400">
    {{ Math.floor(left / 60) }}:{{ String(left % 60).padStart(2, '0') }}
  </div>
</template>

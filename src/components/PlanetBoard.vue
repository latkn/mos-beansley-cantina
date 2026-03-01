<script setup>
defineProps({
  planet: { type: Object, default: null },
  task: { type: Object, default: null },
  timeLeft: { type: Number, default: 0 },
})
</script>

<template>
  <div v-if="planet" class="rounded-xl border-2 border-amber-500/50 bg-slate-900/90 p-6">
    <h2 class="text-2xl font-mono text-amber-400 mb-2">{{ planet.name }}</h2>
    <p v-if="task" class="text-lg text-slate-300 font-mono mb-4">{{ task.task_text }}</p>
    <div class="flex flex-wrap gap-2 mb-4">
      <span
        v-for="m in planet.members"
        :key="m.id"
        class="px-3 py-1 rounded-full bg-slate-700 text-white font-mono text-sm"
      >
        {{ m.callsign }}
      </span>
    </div>
    <div v-if="timeLeft > 0" class="text-3xl font-mono text-cyan-400 tabular-nums">
      {{ Math.floor(timeLeft / 60) }}:{{ String(timeLeft % 60).padStart(2, '0') }}
    </div>
  </div>
</template>

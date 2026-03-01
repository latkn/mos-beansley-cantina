<script setup>
defineProps({
  title: String,
  options: Array,
  modelValue: Number,
})
defineEmits(['update:modelValue'])
</script>

<template>
  <div class="calibration-block">
    <h2 class="text-lg font-mono text-cyan-300 mb-6">{{ title }}</h2>
    <div class="space-y-3">
      <label
        v-for="(opt, idx) in options"
        :key="idx"
        class="block p-4 rounded border cursor-pointer transition"
        :class="modelValue === idx
          ? 'border-cyan-400 bg-cyan-900/30 text-white'
          : 'border-slate-600 bg-slate-800/50 text-slate-300 hover:border-slate-500'"
      >
        <input
          type="radio"
          :name="'block-' + title"
          :value="idx"
          :checked="modelValue === idx"
          class="sr-only"
          @change="$emit('update:modelValue', idx)"
        />
        <span class="font-mono">▢ {{ opt }}</span>
      </label>
    </div>
  </div>
</template>

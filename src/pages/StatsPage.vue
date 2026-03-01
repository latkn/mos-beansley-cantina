<script setup>
import { ref, onMounted } from 'vue'
import { getOrderStats, resetOrderStats } from '@/api/stats'

const stats = ref(null)
const loading = ref(true)
const showResetModal = ref(false)
const resetting = ref(false)
const resetError = ref(null)

async function loadStats() {
  loading.value = true
  try {
    stats.value = await getOrderStats()
  } finally {
    loading.value = false
  }
}

onMounted(loadStats)

function openResetModal() {
  resetError.value = null
  showResetModal.value = true
}

function closeResetModal() {
  if (!resetting.value) showResetModal.value = false
}

async function confirmReset() {
  resetting.value = true
  resetError.value = null
  try {
    await resetOrderStats()
    await loadStats()
    showResetModal.value = false
  } catch (e) {
    resetError.value = e?.message || 'Не удалось сбросить статистику'
  } finally {
    resetting.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-cantina-bg text-cantina-cream p-4 md:p-6 font-sans">
    <div class="max-w-2xl mx-auto">
      <div class="flex flex-wrap items-start justify-between gap-4 mb-6">
        <div>
          <h1 class="font-display text-2xl text-cantina-cream font-semibold mb-1">Статистика</h1>
          <p class="text-cantina-muted text-sm">
            Кофе сварено за сегодня и всего; по типам напитков.
          </p>
        </div>
        <button
          v-if="stats && (stats.totalBrewed > 0 || stats.todayBrewed > 0)"
          type="button"
          class="px-4 py-2 rounded-lg border border-cantina-border text-cantina-muted hover:text-cantina-cream hover:border-cantina-copper/60 transition-colors text-sm font-mono"
          @click="openResetModal"
        >
          Сбросить статистику
        </button>
      </div>

      <div v-if="loading" class="text-cantina-muted py-8">Загрузка…</div>

      <div v-else-if="stats" class="space-y-8">
        <section class="grid grid-cols-2 gap-4">
          <div class="card-cantina">
            <div class="text-cantina-muted text-sm">Сварено сегодня</div>
            <div class="text-3xl font-bold text-cantina-amber">{{ stats.todayBrewed }}</div>
          </div>
          <div class="card-cantina">
            <div class="text-cantina-muted text-sm">Сварено всего</div>
            <div class="text-3xl font-bold text-cantina-copper">{{ stats.totalBrewed }}</div>
          </div>
        </section>

        <section>
          <h2 class="font-display text-lg font-semibold text-cantina-cream mb-3">По типам кофе</h2>
          <ul class="space-y-2">
            <li
              v-for="row in stats.byCoffee"
              :key="row.name"
              class="flex justify-between items-center p-3 rounded-lg bg-cantina-card border border-cantina-border"
            >
              <span class="text-cantina-cream">{{ row.name }}</span>
              <span class="text-cantina-amber font-bold">{{ row.count }}</span>
            </li>
          </ul>
          <p v-if="!stats.byCoffee.length" class="text-cantina-muted text-sm py-4">Пока нет данных</p>
        </section>
      </div>
    </div>

    <!-- Модалка подтверждения сброса статистики -->
    <Teleport to="body">
      <div
        v-if="showResetModal"
        class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm"
        @click.self="closeResetModal"
      >
        <div class="card-cantina max-w-md w-full p-6 md:p-8 border-2 border-cantina-copper/80 shadow-cantina-lg">
          <h2 class="font-display text-xl font-semibold text-cantina-cream mb-2">Сбросить статистику?</h2>
          <p class="text-cantina-muted text-sm mb-6">
            Будут удалены все учтённые заказы (готовые и выданные). Это действие нельзя отменить.
          </p>
          <p v-if="resetError" class="text-red-400 text-sm mb-4">{{ resetError }}</p>
          <div class="flex gap-3">
            <button
              type="button"
              class="flex-1 px-4 py-2.5 rounded-lg border border-cantina-border text-cantina-cream hover:bg-cantina-card transition-colors"
              :disabled="resetting"
              @click="closeResetModal"
            >
              Отмена
            </button>
            <button
              type="button"
              class="flex-1 px-4 py-2.5 rounded-lg bg-red-600/90 hover:bg-red-600 text-white font-medium disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              :disabled="resetting"
              @click="confirmReset"
            >
              {{ resetting ? 'Сброс…' : 'Сбросить' }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

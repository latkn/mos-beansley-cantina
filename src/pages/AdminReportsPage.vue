<script setup>
import { ref, computed, onMounted } from 'vue'
import { getCompletedPlanets } from '@/api/planets'

const reports = ref([])
const loading = ref(true)
const errorMessage = ref('')

async function load() {
  loading.value = true
  errorMessage.value = ''
  try {
    reports.value = await getCompletedPlanets(100)
  } catch (e) {
    errorMessage.value = e?.message || 'Не удалось загрузить отчёты'
  } finally {
    loading.value = false
  }
}

/** Время выполнения: от выдачи задания до завершения. */
function durationSec(planet) {
  const task = planet?.task
  const completedAt = planet?.completed_at
  if (!task?.created_at || !completedAt) return null
  const start = new Date(task.created_at).getTime()
  const end = new Date(completedAt).getTime()
  return Math.max(0, Math.round((end - start) / 1000))
}

function formatDuration(planet) {
  const sec = durationSec(planet)
  if (sec == null) return '—'
  const m = Math.floor(sec / 60)
  const s = sec % 60
  if (m >= 60) {
    const h = Math.floor(m / 60)
    const mm = m % 60
    return `${h} ч ${mm} мин`
  }
  return `${m}:${String(s).padStart(2, '0')}`
}

function formatDateTime(iso) {
  if (!iso) return '—'
  const d = new Date(iso)
  return d.toLocaleString('ru-RU', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

/** Цвет сложности для акцента (как в штабе). */
function difficultyColor(planet) {
  const d = planet?.task?.difficulty ?? 3
  const map = {
    1: 'text-cantina-success',
    2: 'text-cantina-copper-light',
    3: 'text-cantina-amber',
    4: 'text-cantina-copper',
    5: 'text-cantina-danger',
  }
  return map[d] || map[3]
}

const hasReports = computed(() => reports.value.length > 0)

onMounted(load)
</script>

<template>
  <div class="min-h-screen bg-cantina-bg text-cantina-cream font-sans">
    <!-- Тематический заголовок: терминал штаба -->
    <div class="relative overflow-hidden border-b border-cantina-border bg-cantina-surface/80">
      <div class="absolute inset-0 bg-[radial-gradient(ellipse_80%_50%_at_50%_-20%,rgba(184,115,51,0.12),transparent)] pointer-events-none" />
      <div class="relative max-w-4xl mx-auto px-4 py-6 md:py-8">
        <div class="flex flex-wrap items-center justify-between gap-4">
          <div>
            <p class="font-mono text-cantina-copper/90 text-xs uppercase tracking-[0.2em] mb-1">
              Терминал штаба · Лог миссий
            </p>
            <h1 class="font-display text-2xl md:text-3xl font-bold text-cantina-amber">
              Отчёты по заданиям
            </h1>
            <p class="text-cantina-muted text-sm mt-1">
              Выполненные задания в хронологическом порядке
            </p>
          </div>
          <router-link
            to="/admin"
            class="inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-cantina-border text-cantina-sand hover:bg-cantina-card hover:border-cantina-copper/50 transition-colors font-mono text-sm"
          >
            <span class="material-icons text-lg">arrow_back</span>
            Штаб заданий
          </router-link>
        </div>
      </div>
    </div>

    <div class="max-w-4xl mx-auto px-4 py-6 md:py-8">
      <div v-if="loading" class="flex flex-col items-center justify-center py-16">
        <div class="w-12 h-12 border-2 border-cantina-border border-t-cantina-copper rounded-full animate-spin mb-4" />
        <span class="font-mono text-cantina-muted text-sm">Загрузка лога миссий…</span>
      </div>

      <p v-else-if="errorMessage" class="py-8 px-4 rounded-xl bg-cantina-danger/10 border border-cantina-danger/40 text-cantina-danger font-mono text-sm">
        {{ errorMessage }}
      </p>

      <p v-else-if="!hasReports" class="py-16 text-center text-cantina-muted font-mono">
        Пока нет выполненных заданий. Завершённые миссии появятся здесь.
      </p>

      <ul v-else class="space-y-6">
        <li
          v-for="(planet, index) in reports"
          :key="planet.id"
          class="relative"
        >
          <!-- Номер по порядку в стиле «миссия» -->
          <div class="absolute -left-1 top-0 font-mono text-cantina-border text-2xl md:text-3xl select-none tabular-nums">
            {{ String(reports.length - index).padStart(2, '0') }}
          </div>

          <article
            class="rounded-xl border-2 border-cantina-border bg-cantina-card overflow-hidden shadow-cantina hover:border-cantina-copper/40 transition-colors pl-8 md:pl-10"
          >
            <div class="p-4 md:p-6 flex flex-col md:flex-row md:gap-6">
              <!-- Левая колонка: фото + инфо -->
              <div class="flex flex-col gap-4 md:min-w-[200px]">
                <!-- Фотоотчёт -->
                <div class="rounded-lg overflow-hidden bg-cantina-surface border border-cantina-border aspect-[4/3] max-h-[220px] md:max-h-[200px] flex items-center justify-center">
                  <img
                    v-if="planet.photo_url"
                    :src="planet.photo_url"
                    :alt="planet.name"
                    class="w-full h-full object-cover"
                  />
                  <div v-else class="flex flex-col items-center justify-center text-cantina-muted p-4">
                    <span class="material-icons text-4xl mb-2">photo_camera_alt</span>
                    <span class="font-mono text-xs">Фото не приложено</span>
                  </div>
                </div>
                <div class="flex flex-wrap items-center gap-3 text-sm">
                  <span class="font-mono text-cantina-muted" :title="formatDateTime(planet.completed_at)">
                    {{ formatDateTime(planet.completed_at) }}
                  </span>
                  <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-cantina-copper/20 text-cantina-copper font-mono" :title="'Время выполнения'">
                    <span class="material-icons text-base">schedule</span>
                    {{ formatDuration(planet) }}
                  </span>
                </div>
              </div>

              <!-- Правая колонка: название, задание, участники -->
              <div class="flex-1 min-w-0">
                <h2 class="font-display text-lg md:text-xl font-bold text-cantina-amber mb-1">
                  {{ planet.name }}
                </h2>
                <p v-if="planet.task" :class="['font-mono text-sm md:text-base text-cantina-sand mb-4', difficultyColor(planet)]">
                  {{ planet.task.task_text }}
                </p>
                <p v-else class="text-cantina-muted text-sm mb-4">—</p>

                <!-- Участники задания — крупно -->
                <div class="border-t border-cantina-border pt-4">
                  <p class="font-mono text-cantina-copper/90 text-xs uppercase tracking-wider mb-3">
                    Участники миссии
                  </p>
                  <div class="flex flex-wrap gap-3 md:gap-4">
                    <div
                      v-for="m in (planet.members || [])"
                      :key="m.id"
                      class="flex flex-col items-center gap-2 group"
                    >
                      <div class="w-14 h-14 md:w-16 md:h-16 rounded-xl overflow-hidden bg-cantina-surface border-2 border-cantina-border group-hover:border-cantina-copper/50 transition-colors flex-shrink-0 shadow-cantina">
                        <img
                          v-if="m.avatar_url"
                          :src="m.avatar_url"
                          :alt="m.callsign"
                          class="w-full h-full object-cover"
                        />
                        <div
                          v-else
                          class="w-full h-full flex items-center justify-center text-cantina-muted font-bold text-xl"
                        >
                          {{ (m.callsign || '?').slice(0, 1) }}
                        </div>
                      </div>
                      <span class="font-mono text-cantina-cream text-sm font-medium text-center max-w-[4.5rem] truncate" :title="m.callsign">
                        {{ m.callsign || 'Гость' }}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Статус: выполнено с фото / без -->
            <div class="px-4 md:px-6 py-2 bg-cantina-surface/60 border-t border-cantina-border flex items-center gap-2">
              <span class="material-icons text-cantina-success text-lg">check_circle</span>
              <span class="font-mono text-xs text-cantina-muted">
                Задание выполнено
                <template v-if="planet.photo_url"> · Фотоотчёт приложен</template>
                <template v-else> · Без фото</template>
              </span>
            </div>
          </article>
        </li>
      </ul>
    </div>
  </div>
</template>

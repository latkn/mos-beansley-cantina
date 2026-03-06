<script setup>
import { ref } from 'vue'
import { resetDatabase } from '@/api/resetDb'

const resetModalOpen = ref(false)
const resetSubmitting = ref(false)
const resetError = ref('')

function openResetModal() {
  resetModalOpen.value = true
  resetError.value = ''
}

function closeResetModal() {
  if (resetSubmitting.value) return
  resetModalOpen.value = false
  resetError.value = ''
}

async function confirmResetDb() {
  if (resetSubmitting.value) return
  resetSubmitting.value = true
  resetError.value = ''
  try {
    await resetDatabase()
    closeResetModal()
  } catch (e) {
    resetError.value = e?.message || 'Ошибка сброса'
  } finally {
    resetSubmitting.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-cantina-bg text-cantina-cream p-4 md:p-6 font-sans">
    <div class="max-w-lg mx-auto">
      <div class="flex items-center justify-between gap-4 mb-8">
        <h1 class="font-display text-2xl text-cantina-amber">Админ</h1>
        <router-link to="/admin" class="text-cantina-sand hover:text-cantina-cream text-sm transition-colors">← Штаб заданий</router-link>
      </div>

      <p class="text-cantina-muted text-sm mb-6">
        Выберите раздел: списки для редактирования или участники.
      </p>

      <nav class="space-y-3">
        <router-link
          to="/admin/guests"
          class="block card-cantina p-5 text-left transition hover:border-cantina-copper/60"
        >
          <span class="text-cantina-copper text-xs uppercase tracking-wider font-mono">Участники</span>
          <span class="mt-1 block text-lg text-cantina-cream font-mono">Гости</span>
          <span class="mt-0.5 block text-cantina-muted text-sm">Просмотр, заметка бариста, удаление записей</span>
        </router-link>

        <router-link
          to="/admin/coffee"
          class="block card-cantina p-5 text-left transition hover:border-cantina-copper/60"
        >
          <span class="text-cantina-copper text-xs uppercase tracking-wider font-mono">Списки</span>
          <span class="mt-1 block text-lg text-cantina-cream font-mono">Кофейная карта</span>
          <span class="mt-0.5 block text-cantina-muted text-sm">Позиции напитков, баллы, инструкции для бариста</span>
        </router-link>

        <router-link
          to="/admin/quiz"
          class="block card-cantina p-5 text-left transition hover:border-cantina-copper/60"
        >
          <span class="text-cantina-copper text-xs uppercase tracking-wider font-mono">Списки</span>
          <span class="mt-1 block text-lg text-cantina-cream font-mono">Вопросы подбора напитков</span>
          <span class="mt-0.5 block text-cantina-muted text-sm">Вопросы и ответы с весами для профиля гостя</span>
        </router-link>

        <router-link
          to="/admin/allergens"
          class="block card-cantina p-5 text-left transition hover:border-cantina-copper/60"
        >
          <span class="text-cantina-copper text-xs uppercase tracking-wider font-mono">Списки</span>
          <span class="mt-1 block text-lg text-cantina-cream font-mono">Аллергены</span>
          <span class="mt-0.5 block text-cantina-muted text-sm">Пункты для опросника «на что аллергия»</span>
        </router-link>

        <router-link
          to="/admin/tasks"
          class="block card-cantina p-5 text-left transition hover:border-cantina-copper/60"
        >
          <span class="text-cantina-copper text-xs uppercase tracking-wider font-mono">Списки</span>
          <span class="mt-1 block text-lg text-cantina-cream font-mono">Задания штаба</span>
          <span class="mt-0.5 block text-cantina-muted text-sm">Задания для «объединить расу» и вывода на табло</span>
        </router-link>

        <router-link
          to="/admin/reports"
          class="block card-cantina p-5 text-left transition hover:border-cantina-copper/60"
        >
          <span class="text-cantina-copper text-xs uppercase tracking-wider font-mono">Штаб</span>
          <span class="mt-1 block text-lg text-cantina-cream font-mono">Отчёты по заданиям</span>
          <span class="mt-0.5 block text-cantina-muted text-sm">Выполненные задания: хронология, фотоотчёты, участники, время</span>
        </router-link>
      </nav>

      <div class="mt-10 pt-6 border-t border-cantina-border">
        <button
          type="button"
          class="w-full py-3 px-4 rounded-xl border-2 border-cantina-danger/50 bg-cantina-danger/10 text-cantina-danger font-mono font-semibold hover:bg-cantina-danger/20 transition-colors"
          @click="openResetModal"
        >
          Обнулить базу данных полностью
        </button>
      </div>
    </div>

    <!-- Модалка подтверждения сброса БД -->
    <Teleport to="body">
      <div
        v-if="resetModalOpen"
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60"
        @click.self="closeResetModal"
      >
        <div class="bg-cantina-card border-2 border-cantina-danger rounded-xl p-6 max-w-sm w-full shadow-cantina">
          <h3 class="font-display text-lg font-semibold text-cantina-danger mb-2">Обнулить базу данных?</h3>
          <p class="text-cantina-sand text-sm mb-4">
            Будут удалены все гости, заказы, планеты, задания, вопросы квиза, кофейная карта, аллергены, расы и файлы в хранилище. Действие необратимо.
          </p>
          <p v-if="resetError" class="mb-4 text-cantina-danger text-sm">{{ resetError }}</p>
          <div class="flex gap-2">
            <button
              type="button"
              class="flex-1 py-2 rounded-lg bg-cantina-danger hover:bg-cantina-danger/90 text-white font-semibold disabled:opacity-50"
              :disabled="resetSubmitting"
              @click="confirmResetDb"
            >
              {{ resetSubmitting ? '…' : 'Да, обнулить' }}
            </button>
            <button
              type="button"
              class="px-4 py-2 rounded-lg border border-cantina-border text-cantina-sand hover:bg-cantina-surface"
              :disabled="resetSubmitting"
              @click="closeResetModal"
            >
              Отмена
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

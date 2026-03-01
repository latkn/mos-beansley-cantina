<script setup>
import { RouterView } from 'vue-router'
import { onMounted } from 'vue'
import { flushPendingSync } from '@/lib/sync'

onMounted(() => {
  window.addEventListener('online', flushPendingSync)
  if (navigator.onLine) flushPendingSync()
})
</script>

<template>
  <div class="min-h-screen bg-cantina-bg">
    <nav class="border-b border-cantina-border bg-cantina-surface/95 px-4 py-2.5 flex flex-wrap items-center gap-4 font-mono text-sm">
      <div class="flex flex-wrap gap-4">
        <router-link
          to="/register"
          class="text-cantina-sand hover:text-cantina-copper-light transition-colors"
        >
          Регистрация
        </router-link>
        <router-link
          to="/board"
          class="text-cantina-sand hover:text-cantina-copper-light transition-colors"
        >
          Табло
        </router-link>
        <router-link
          to="/barista"
          class="text-cantina-amber hover:text-cantina-copper-light transition-colors"
        >
          Бариста
        </router-link>
        <router-link
          to="/stats"
          class="text-cantina-sand hover:text-cantina-copper-light transition-colors"
        >
          Статистика
        </router-link>
        <router-link
          to="/admin"
          class="text-cantina-amber hover:text-cantina-copper-light transition-colors"
        >
          Штаб заданий
        </router-link>
      </div>
      <router-link
        to="/admin/edit"
        class="ml-auto text-cantina-muted/70 hover:text-cantina-sand text-xs transition-colors"
      >
        Терминал штаба
      </router-link>
    </nav>
    <RouterView />
  </div>
</template>

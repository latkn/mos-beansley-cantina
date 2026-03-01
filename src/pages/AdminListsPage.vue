<script setup>
// Страница только со ссылками на разделы с редактированием списков
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
    </div>
  </div>
</template>

import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  { path: '/', redirect: '/register' },
  { path: '/register', name: 'Register', component: () => import('@/pages/RegisterPage.vue'), meta: { title: 'Регистрация' } },
  { path: '/guest/:callsign', name: 'Guest', component: () => import('@/pages/GuestPage.vue'), meta: { title: 'Профиль' } },
  { path: '/board', name: 'Board', component: () => import('@/pages/BoardPage.vue'), meta: { title: 'Табло' } },
  { path: '/barista', name: 'Barista', component: () => import('@/pages/BaristaPage.vue'), meta: { title: 'Бариста' } },
  { path: '/admin', name: 'Admin', component: () => import('@/pages/AdminPage.vue'), meta: { title: 'Штаб заданий' } },
  { path: '/admin/tamada', name: 'TamadaTerminal', component: () => import('@/pages/TamadaTerminalPage.vue'), meta: { title: 'Терминал тамады' } },
  { path: '/admin/edit', name: 'AdminLists', component: () => import('@/pages/AdminListsPage.vue'), meta: { title: 'Админ' } },
  { path: '/admin/guests', name: 'AdminGuests', component: () => import('@/pages/AdminGuestsPage.vue'), meta: { title: 'Участники' } },
  { path: '/admin/coffee', name: 'CoffeeMenuAdmin', component: () => import('@/pages/CoffeeMenuAdminPage.vue'), meta: { title: 'Кофейная карта' } },
  { path: '/admin/quiz', name: 'QuizAdmin', component: () => import('@/pages/QuizAdminPage.vue'), meta: { title: 'Вопросы подбора' } },
  { path: '/admin/allergens', name: 'AllergensAdmin', component: () => import('@/pages/AllergensAdminPage.vue'), meta: { title: 'Аллергены' } },
  { path: '/admin/tasks', name: 'TamadaTasksAdmin', component: () => import('@/pages/TamadaTasksAdminPage.vue'), meta: { title: 'Задания штаба' } },
  { path: '/admin/reports', name: 'AdminReports', component: () => import('@/pages/AdminReportsPage.vue'), meta: { title: 'Отчёты по заданиям' } },
  { path: '/tamada', name: 'TamadaParticipant', component: () => import('@/pages/TamadaParticipantPage.vue'), meta: { title: 'Завершить задание' } },
  { path: '/stats', name: 'Stats', component: () => import('@/pages/StatsPage.vue'), meta: { title: 'Статистика' } },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.afterEach((to) => {
  document.title = to.meta?.title ? `${to.meta.title} — Cosmic Cantina` : 'Cosmic Cantina'
})

export default router

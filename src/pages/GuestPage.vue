<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { getGuestByCallsign } from '@/api/guests'
import GuestCard from '@/components/GuestCard.vue'

const route = useRoute()
const guest = ref(null)
const loading = ref(true)

const callsign = computed(() => route.params.callsign?.toUpperCase() || '')

onMounted(async () => {
  if (!callsign.value) return
  guest.value = await getGuestByCallsign(callsign.value)
  loading.value = false
})
</script>

<template>
  <div class="min-h-screen bg-cantina-bg text-cantina-cream p-4 md:p-6 font-sans">
    <div class="max-w-lg mx-auto">
      <div v-if="loading" class="text-cantina-muted">Загрузка профиля…</div>
      <template v-else-if="guest">
        <h1 class="font-display text-xl text-cantina-cream font-semibold mb-4">Профиль</h1>
        <GuestCard :guest="guest" />
        <p class="mt-6 text-cantina-muted text-center text-sm">
          Напиток подобран по вашему профилю. Ожидайте у стойки бариста — когда будет готово, вас вызовут по позывному.
        </p>
      </template>
      <div v-else class="text-cantina-muted">
        Позывной «{{ callsign }}» не найден.
        <router-link to="/register" class="text-cantina-copper hover:text-cantina-copper-light transition-colors">Зарегистрироваться</router-link>
      </div>
    </div>
  </div>
</template>

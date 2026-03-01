<script setup>
import { ref, computed, watch, nextTick, onMounted, onUnmounted } from 'vue'
import { uploadPlanetPhoto, completePlanetWithPhoto } from '@/api/planets'

const props = defineProps({
  planet: { type: Object, default: null },
  modelValue: { type: Boolean, default: false },
})
const emit = defineEmits(['update:modelValue', 'done'])

const TASK_DURATION_SEC = 5 * 60
const COUNTDOWN_SEC = 3

const countdown = ref(0)
const step = ref('idle') // 'idle' | 'countdown' | 'capture' | 'uploading'
const fileInput = ref(null)
const uploading = ref(false)
const errorMessage = ref('')
/** Обновляется раз в секунду, чтобы таймер в модалке шёл */
const now = ref(Date.now())
let timerInterval = null

const deadlineAt = computed(() => {
  const task = props.planet?.task
  if (!task?.created_at) return null
  return new Date(new Date(task.created_at).getTime() + TASK_DURATION_SEC * 1000)
})

const timeLeftSec = computed(() => {
  const d = deadlineAt.value
  if (!d) return 0
  const left = Math.ceil((d - now.value) / 1000)
  return Math.max(0, left)
})

const isOverdue = computed(() => deadlineAt.value && now.value > deadlineAt.value)

const timeDisplay = computed(() => {
  const s = timeLeftSec.value
  const m = Math.floor(s / 60)
  const sec = s % 60
  return `${m}:${String(sec).padStart(2, '0')}`
})

watch(
  () => props.modelValue,
  (open) => {
    if (open) {
      step.value = 'idle'
      countdown.value = 0
      errorMessage.value = ''
      now.value = Date.now()
      if (timerInterval) clearInterval(timerInterval)
      timerInterval = setInterval(() => { now.value = Date.now() }, 1000)
    } else {
      if (timerInterval) {
        clearInterval(timerInterval)
        timerInterval = null
      }
    }
  }
)

onUnmounted(() => {
  if (timerInterval) clearInterval(timerInterval)
})

function startPhotoCapture() {
  step.value = 'countdown'
  countdown.value = COUNTDOWN_SEC
  const t = setInterval(() => {
    countdown.value--
    if (countdown.value <= 0) {
      clearInterval(t)
      step.value = 'capture'
      nextTick(() => fileInput.value?.click())
    }
  }, 1000)
}

async function onFileSelected(e) {
  const file = e.target?.files?.[0]
  e.target.value = ''
  if (!file || !props.planet?.id) return
  uploading.value = true
  errorMessage.value = ''
  try {
    const url = await uploadPlanetPhoto(props.planet.id, file)
    await completePlanetWithPhoto(props.planet.id, url)
    emit('done')
    emit('update:modelValue', false)
  } catch (err) {
    errorMessage.value = err?.message || 'Ошибка загрузки'
  } finally {
    uploading.value = false
    step.value = 'idle'
  }
}

function close() {
  if (!uploading.value) {
    emit('update:modelValue', false)
  }
}
</script>

<template>
  <Teleport to="body">
    <div
      v-if="modelValue"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70"
      @click.self="close"
    >
      <div
        class="bg-cantina-card border-2 border-cantina-copper/50 rounded-xl max-w-lg w-full max-h-[90vh] overflow-y-auto shadow-cantina-lg"
        @click.stop
      >
        <div class="p-6 space-y-4">
          <div class="flex justify-between items-start">
            <h3 class="font-display text-xl font-mono text-cantina-copper">{{ planet?.name }}</h3>
            <button
              type="button"
              class="text-cantina-muted hover:text-cantina-cream p-1 transition-colors"
              :disabled="uploading"
              @click="close"
            >
              ✕
            </button>
          </div>

          <p v-if="planet?.task" class="text-lg md:text-xl text-cantina-cream font-mono">
            {{ planet.task.task_text }}
          </p>

          <div class="flex items-center gap-3">
            <span v-if="!isOverdue" class="font-mono text-3xl tabular-nums text-cantina-copper">
              {{ timeDisplay }}
            </span>
            <span v-else class="px-3 py-1 rounded bg-cantina-amber/30 text-cantina-amber font-mono">
              Просрочено
            </span>
          </div>

          <!-- Участники задания -->
          <div v-if="planet?.members?.length" class="border-t border-cantina-border pt-4">
            <h4 class="text-cantina-sand text-sm font-bold uppercase tracking-wider mb-2">Участники</h4>
            <div class="flex flex-wrap gap-3">
              <div
                v-for="m in planet.members"
                :key="m.id"
                class="flex items-center gap-2 px-3 py-2 rounded-lg bg-cantina-surface border border-cantina-border"
              >
                <div class="w-10 h-10 rounded-full bg-cantina-surface overflow-hidden flex-shrink-0 border border-cantina-border">
                  <img
                    v-if="m.avatar_url"
                    :src="m.avatar_url"
                    :alt="m.callsign"
                    class="w-full h-full object-cover"
                  />
                  <div
                    v-else
                    class="w-full h-full flex items-center justify-center text-cantina-muted text-sm font-bold"
                  >
                    ?
                  </div>
                </div>
                <span class="font-mono text-cantina-cream font-medium">{{ m.callsign || 'Гость' }}</span>
              </div>
            </div>
          </div>

          <div v-if="step === 'idle'" class="pt-2">
            <button
              type="button"
              class="btn-cantina-primary w-full py-3 rounded-lg font-mono font-bold"
              @click="startPhotoCapture"
            >
              Приложить фото и завершить
            </button>
          </div>

          <div v-else-if="step === 'countdown'" class="py-4 text-center">
            <p class="text-cantina-muted text-sm mb-2">Снимок через</p>
            <p class="font-mono text-6xl text-cantina-copper tabular-nums">{{ countdown }}</p>
          </div>

          <div v-else-if="step === 'capture'" class="pt-2">
            <input
              ref="fileInput"
              type="file"
              accept="image/*"
              capture="environment"
              class="hidden"
              @change="onFileSelected"
            />
            <p class="text-cantina-muted text-sm mb-2">Выберите фото или сделайте снимок</p>
            <button
              type="button"
              class="btn-cantina-secondary w-full py-3 rounded-lg font-mono"
              @click="fileInput?.click()"
            >
              Выбрать файл
            </button>
          </div>

          <div v-if="uploading" class="text-cantina-amber font-mono">Загрузка…</div>
          <div v-if="errorMessage" class="text-cantina-danger text-sm">{{ errorMessage }}</div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

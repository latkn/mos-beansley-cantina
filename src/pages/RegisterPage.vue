<script setup>
import { ref, computed, watch, onUnmounted, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from '@/i18n'
import { createGuest, getRecentGuests, updateGuest } from '@/api/guests'
import { getRecommendedCoffeesByProfile, getCoffeeMenu } from '@/api/coffee'
import { createOrder, getOrdersByGuestId } from '@/api/orders'
import { getRandomQuestions } from '@/api/questions'
import { getAllergens } from '@/api/allergens'
import { getRaces } from '@/api/races'
import { calculateProfileFromAnswers } from '@/lib/quizProfile'
import { getRaceIdFromProfile, getRaceNameBySlug, getRaceSlugFromProfile } from '@/lib/raceFromProfile'
import GuestCard from '@/components/GuestCard.vue'

const router = useRouter()
const logoImg = new URL('../assets/logo.png', import.meta.url).href
const { t, locale, setLocale } = useI18n()

const step = ref(0)
const callsign = ref('')
const callsignError = ref('')
const photoDataUrl = ref('')
const result = ref(null)
const allergiesInput = ref('')
const isSubmitting = ref(false)
const quizQuestions = ref([])
const quizAnswers = ref([])
const quizStep = ref(0)
const showQuiz = ref(false)
const selectedQuizAnswerId = ref(null)
const allergensList = ref([])
const showAllergiesStep = ref(false)
const selectedAllergenLabels = ref([])
const allergiesExtraInput = ref('')
const videoRef = ref(null)
const canvasRef = ref(null)
const scanCountdown = ref(0) // 0 = idle, 3/2/1 = countdown
let countdownTimerId = null
const recentGuests = ref([])
const selectedExistingGuest = ref(null)
const showGuestDetailView = ref(false)
const guestOrders = ref([])
const registeredMessage = ref('')
/** Модальное сообщение после квиза: раса + подбор напитка. Закрывается только по кнопке «Хорошо». */
const showRaceResultModal = ref(false)
const raceResultRaceName = ref('')
/** После аллергий: шаг корректировки 4 параметров перед подбором напитка */
const showProfileAdjustStep = ref(false)
const editableProfile = ref({ sweetness: 5, bitterness: 5, intensity: 5, extremeness: 5 })
/** После фото (новая регистрация): показать ввод позывного перед квизом */
const showCallsignAfterPhoto = ref(false)
/** null = два варианта на выбор, 'returning' = выбор аватарки + поиск, 'new' = новая регистрация */
const landingChoice = ref(null)
const returningSearchQuery = ref('')
let streamRef = null

// UX: loaders
const isLoadingRecentGuests = ref(false)
const isLoadingGuestDetail = ref(false)
const isLoadingOrderFlow = ref(false)
const isLoadingNextStep = ref(false)
const isFinishingExisting = ref(false)

const filteredGuestsForReturning = computed(() => {
  const q = (returningSearchQuery.value || '').trim().toUpperCase()
  if (!q) return recentGuests.value
  return recentGuests.value.filter((g) => (g.callsign || '').toUpperCase().includes(q))
})

async function loadRecentGuests() {
  isLoadingRecentGuests.value = true
  try {
    recentGuests.value = await getRecentGuests(20)
  } finally {
    isLoadingRecentGuests.value = false
  }
}

onMounted(() => {
  loadRecentGuests()
})

watch(step, async (s) => {
  if (s === 1 && !photoDataUrl.value && !streamRef) await startCamera()
})

async function startCamera() {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'user' } })
    streamRef = stream
    if (videoRef.value) {
      videoRef.value.srcObject = stream
      await new Promise((r) => { videoRef.value.onloadedmetadata = r })
    }
  } catch (e) {
    streamRef = null
  }
}

function doCaptureFromVideo() {
  if (!canvasRef.value || !videoRef.value || !videoRef.value.videoWidth) return
  const w = videoRef.value.videoWidth
  const h = videoRef.value.videoHeight
  canvasRef.value.width = w
  canvasRef.value.height = h
  canvasRef.value.getContext('2d').drawImage(videoRef.value, 0, 0)
  photoDataUrl.value = canvasRef.value.toDataURL('image/jpeg', 0.8)
  if (streamRef) {
    streamRef.getTracks().forEach((t) => t.stop())
    streamRef = null
  }
  if (countdownTimerId) clearInterval(countdownTimerId)
  countdownTimerId = null
  scanCountdown.value = 0
}

function startCountdownThenCapture() {
  if (scanCountdown.value > 0) return
  if (!streamRef) {
    startCamera().then(() => {
      if (streamRef) startCountdownThenCapture()
      else fallbackFileInput()
    })
    return
  }
  scanCountdown.value = 3
  countdownTimerId = setInterval(() => {
    scanCountdown.value -= 1
    if (scanCountdown.value <= 0) {
      if (countdownTimerId) clearInterval(countdownTimerId)
      countdownTimerId = null
      doCaptureFromVideo()
    }
  }, 1000)
}

function fallbackFileInput() {
  const input = document.createElement('input')
  input.type = 'file'
  input.accept = 'image/*'
  input.onchange = (ev) => {
    const f = ev.target.files?.[0]
    if (f) {
      const r = new FileReader()
      r.onload = () => { photoDataUrl.value = r.result }
      r.readAsDataURL(f)
    }
  }
  input.click()
}

async function capturePhoto() {
  try {
    if (!streamRef) await startCamera()
    if (!streamRef) {
      fallbackFileInput()
      return
    }
    startCountdownThenCapture()
  } catch (e) {
    fallbackFileInput()
  }
}

function closeRaceResultModal() {
  showRaceResultModal.value = false
}

onUnmounted(() => {
  if (countdownTimerId) clearInterval(countdownTimerId)
  if (streamRef) streamRef.getTracks().forEach((t) => t.stop())
})

function generateCallsign() {
  return 'G-' + Date.now().toString(36).toUpperCase().slice(-6) + '-' + Math.random().toString(36).slice(2, 5).toUpperCase()
}

async function selectExistingGuest(guest) {
  selectedExistingGuest.value = guest
  callsign.value = guest.callsign
  photoDataUrl.value = guest.avatar_url || ''
  const guestAllergies = Array.isArray(guest.allergies) ? guest.allergies : (guest.allergies ? [guest.allergies] : [])
  allergiesInput.value = guestAllergies.join(', ')
  selectedAllergenLabels.value = [...guestAllergies]
  allergiesExtraInput.value = ''
  showGuestDetailView.value = true
  isLoadingGuestDetail.value = true
  try {
    guestOrders.value = await getOrdersByGuestId(guest.id)
    step.value = 2
  } finally {
    isLoadingGuestDetail.value = false
  }
}

async function startOrderFlowForExistingGuest() {
  const guest = selectedExistingGuest.value
  if (!guest) return
  isLoadingOrderFlow.value = true
  try {
    const [questions, allergens] = await Promise.all([getRandomQuestions(5), getAllergens()])
    allergensList.value = allergens
    if (questions.length > 0) {
      quizQuestions.value = questions
      quizStep.value = 0
      quizAnswers.value = []
      result.value = null
      showQuiz.value = true
      showAllergiesStep.value = false
      selectedQuizAnswerId.value = null
    } else {
      showQuiz.value = false
      showAllergiesStep.value = true
      result.value = null
    }
    showGuestDetailView.value = false
  } finally {
    isLoadingOrderFlow.value = false
  }
}

function parseAllergies(s) {
  return String(s ?? '')
    .split(',')
    .map((x) => x.trim())
    .filter(Boolean)
}

/** Флаг готовности к отправке (профиль из квиза или без вопросов в БД) */
function defaultResult() {
  return { ready: true }
}

function goAfterPhoto() {
  if (landingChoice.value === 'new') {
    showCallsignAfterPhoto.value = true
  } else {
    nextPhoto()
  }
}

function acceptCallsignAndContinue() {
  callsignError.value = ''
  const raw = callsign.value.trim()
  if (raw.length < 2) {
    callsignError.value = 'Введите минимум 2 символа'
    return
  }
  showCallsignAfterPhoto.value = false
  nextPhoto()
}

async function nextPhoto() {
  isLoadingNextStep.value = true
  try {
    const [allergens, questions] = await Promise.all([getAllergens(), getRandomQuestions(5)])
    allergensList.value = allergens
    selectedAllergenLabels.value = []
    allergiesExtraInput.value = ''
    if (questions.length > 0) {
      quizQuestions.value = questions
      quizStep.value = 0
      quizAnswers.value = []
      showQuiz.value = true
      showAllergiesStep.value = false
      result.value = null
      selectedQuizAnswerId.value = null
    } else {
      showQuiz.value = false
      showAllergiesStep.value = true
      result.value = null
    }
    step.value = 2
  } finally {
    isLoadingNextStep.value = false
  }
}

function getCurrentQuizQuestion() {
  return quizQuestions.value[quizStep.value] ?? null
}

function selectQuizAnswer(answer) {
  selectedQuizAnswerId.value = answer.id
}

async function nextQuizQuestion() {
  const q = getCurrentQuizQuestion()
  const answer = q?.quiz_answers?.find((a) => a.id === selectedQuizAnswerId.value)
  if (!q || !answer) return
  quizAnswers.value.push({ question: q, answer })
  selectedQuizAnswerId.value = null
  if (quizStep.value + 1 >= quizQuestions.value.length) {
    showQuiz.value = false
    showAllergiesStep.value = true
  } else {
    quizStep.value += 1
  }
}

function toggleAllergen(label) {
  const idx = selectedAllergenLabels.value.indexOf(label)
  if (idx >= 0) {
    selectedAllergenLabels.value = selectedAllergenLabels.value.filter((l) => l !== label)
  } else {
    selectedAllergenLabels.value = [...selectedAllergenLabels.value, label]
  }
}

async function confirmAllergiesStep() {
  const selected = [...selectedAllergenLabels.value]
  const extra = parseAllergies(allergiesExtraInput.value)
  const allergies = [...selected, ...extra]
  allergiesInput.value = allergies.join(', ')
  showAllergiesStep.value = false

  if (quizAnswers.value.length > 0) {
    const payload = quizAnswers.value.map(({ question, answer }) => ({ question, answer }))
    const { normalized: profile } = calculateProfileFromAnswers(payload)
    editableProfile.value = {
      sweetness: profile.sweetness,
      bitterness: profile.bitterness,
      intensity: profile.intensity,
      extremeness: profile.extremeness,
    }
  } else {
    editableProfile.value = { sweetness: 5, bitterness: 5, intensity: 5, extremeness: 5 }
  }
  showProfileAdjustStep.value = true
}

async function confirmProfileAndContinue() {
  const profile = { ...editableProfile.value }
  showProfileAdjustStep.value = false
  result.value = defaultResult()

  const races = await getRaces()
  const raceId = getRaceIdFromProfile(profile, races)
  const slug = getRaceSlugFromProfile(profile)
  const race = races.find((r) => r.slug === slug)
  raceResultRaceName.value = race?.name ?? getRaceNameBySlug(slug)

  if (selectedExistingGuest.value) {
    try {
      await updateGuest(selectedExistingGuest.value.id, {
        sweetness: profile.sweetness,
        bitterness: profile.bitterness,
        intensity: profile.intensity,
        extremeness: profile.extremeness,
        race_id: raceId,
        allergies: parseAllergies(allergiesInput.value),
      })
    } catch (_) {}
  }

  showRaceResultModal.value = true
}


async function assignDrinkAndCreateOrder(guestId, profileOverride = null) {
  const allergies = parseAllergies(allergiesInput.value)
  const profile = profileOverride ?? (quizAnswers.value.length > 0
    ? (() => {
        const payload = quizAnswers.value.map(({ question, answer }) => ({ question, answer }))
        const { normalized } = calculateProfileFromAnswers(payload)
        return normalized
      })()
    : { sweetness: 5, bitterness: 5, intensity: 5, extremeness: 5 })
  let list = await getRecommendedCoffeesByProfile(profile, allergies, 1)
  if (list.length === 0) {
    const menu = await getCoffeeMenu()
    list = menu.length ? [menu[0]] : []
  }
  if (list.length > 0) {
    await createOrder(guestId, list[0])
  }
}

async function submitRegistration() {
  if (!result.value || isSubmitting.value) return
  isSubmitting.value = true
  callsignError.value = ''
  try {
    const finalCallsign = selectedExistingGuest.value
      ? selectedExistingGuest.value.callsign
      : (callsign.value.trim().toUpperCase() || generateCallsign())
    const profile = editableProfile.value
    const payload = {
      callsign: finalCallsign,
      avatar_url: photoDataUrl.value || null,
      allergies: parseAllergies(allergiesInput.value),
      sweetness: profile.sweetness,
      bitterness: profile.bitterness,
      intensity: profile.intensity,
      extremeness: profile.extremeness,
    }
    const races = await getRaces()
    payload.race_id = getRaceIdFromProfile(profile, races)
    const guest = await createGuest(payload)
    await assignDrinkAndCreateOrder(guest.id, profile)
    restart()
    router.push({ name: 'Register' })
  } catch (e) {
    callsignError.value = e?.message || t('register.registrationError')
  } finally {
    isSubmitting.value = false
  }
}

function restart() {
  closeRaceResultModal()
  step.value = 0
  landingChoice.value = null
  returningSearchQuery.value = ''
  callsign.value = ''
  photoDataUrl.value = ''
  result.value = null
  quizQuestions.value = []
  quizAnswers.value = []
  quizStep.value = 0
  showQuiz.value = false
  showAllergiesStep.value = false
  showProfileAdjustStep.value = false
  editableProfile.value = { sweetness: 5, bitterness: 5, intensity: 5, extremeness: 5 }
  showGuestDetailView.value = false
  guestOrders.value = []
  selectedQuizAnswerId.value = null
  allergensList.value = []
  selectedAllergenLabels.value = []
  allergiesExtraInput.value = ''
  selectedExistingGuest.value = null
  showCallsignAfterPhoto.value = false
}

function chooseReturning() {
  landingChoice.value = 'returning'
  loadRecentGuests()
}

function chooseNew() {
  landingChoice.value = 'new'
  callsignError.value = ''
  step.value = 1
}

function backToLanding() {
  landingChoice.value = null
  returningSearchQuery.value = ''
  callsign.value = ''
  callsignError.value = ''
}

function backToRegisterList() {
  restart()
  loadRecentGuests()
}

async function finishAsExistingGuest() {
  if (selectedExistingGuest.value) {
    isFinishingExisting.value = true
    try {
      const profile = editableProfile.value
      await updateGuest(selectedExistingGuest.value.id, {
        allergies: parseAllergies(allergiesInput.value),
        sweetness: profile.sweetness,
        bitterness: profile.bitterness,
        intensity: profile.intensity,
        extremeness: profile.extremeness,
      })
      await assignDrinkAndCreateOrder(selectedExistingGuest.value.id, profile)
      restart()
      router.push({ name: 'Register' })
    } catch (_) {
      backToRegisterList()
    } finally {
      isFinishingExisting.value = false
    }
  } else {
    backToRegisterList()
  }
}
</script>

<template>
  <div class="min-h-screen bg-cantina-bg text-cantina-cream p-4 md:p-6 font-sans">
    <!-- Модальное сообщение после квиза: раса + подбор напитка. -->
    <Teleport to="body">
      <div
        v-if="showRaceResultModal"
        class="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm"
        @click.self="closeRaceResultModal"
      >
        <div class="card-cantina max-w-lg w-full p-8 md:p-10 text-center space-y-8 border-2 border-cantina-copper/80 shadow-cantina-lg">
          <p class="text-cantina-sand text-sm uppercase tracking-[0.2em] font-mono">{{ t('register.biometryDone') }}</p>
          <h2 class="font-display text-2xl md:text-4xl font-semibold text-cantina-cream leading-tight">
            {{ t('register.yourRace') }} <span class="text-cantina-copper">{{ raceResultRaceName }}</span>
          </h2>
          <p class="text-xl md:text-2xl text-cantina-cream/90 leading-snug">
            {{ t('register.drinkWillMatch') }}
          </p>
          <button
            type="button"
            class="btn-cantina-primary w-full py-4 font-mono text-lg uppercase tracking-wider"
            @click="closeRaceResultModal"
          >
            {{ t('register.ok') }}
          </button>
        </div>
      </div>
    </Teleport>
    <div class="max-w-lg mx-auto">
      <!-- Экран выбора: уже калиброван или первичная калибровка -->
      <div v-if="step === 0 && landingChoice === null" class="space-y-8 py-4">
        <div class="flex justify-end gap-2">
          <button
            type="button"
            class="px-2 py-1 rounded-lg text-xs font-mono transition-colors"
            :class="locale === 'ru' ? 'bg-cantina-copper text-cantina-cream' : 'text-cantina-muted hover:text-cantina-sand'"
            @click="setLocale('ru')"
          >
            RU
          </button>
          <button
            type="button"
            class="px-2 py-1 rounded-lg text-xs font-mono transition-colors"
            :class="locale === 'en' ? 'bg-cantina-copper text-cantina-cream' : 'text-cantina-muted hover:text-cantina-sand'"
            @click="setLocale('en')"
          >
            EN
          </button>
        </div>
        <div class="flex justify-center">
          <img
            :src="logoImg"
            alt="Mos Beansley Cantina"
            class="h-40 md:h-40 w-auto object-contain opacity-95"
          />
        </div>
        <p class="text-cantina-muted text-xs uppercase tracking-[0.2em] text-center font-mono">{{ t('register.entryPoint') }}</p>
        <h1 class="font-display text-2xl md:text-3xl text-cantina-cream font-semibold text-center leading-tight">
          {{ t('register.systemTitle') }}<br />{{ t('register.confirmStatus') }}
        </h1>
        <p v-if="registeredMessage" class="text-cantina-success font-mono text-center text-sm">{{ registeredMessage }}</p>
        <div class="grid gap-4">
          <button
            type="button"
            class="card-cantina group relative overflow-hidden rounded-xl border-2 border-cantina-copper/60 px-6 py-8 text-left transition hover:border-cantina-copper-light focus:outline-none focus:ring-2 focus:ring-cantina-copper"
            @click="chooseReturning"
          >
            <span class="absolute inset-0 bg-gradient-to-br from-cantina-copper/10 to-transparent pointer-events-none" />
            <span class="relative block">
              <span class="text-cantina-copper text-xs uppercase tracking-widest font-mono">{{ t('register.previouslyCalibrated') }}</span>
              <span class="mt-2 block text-lg md:text-xl text-cantina-cream font-mono">{{ t('register.myBiometryInRegistry') }}</span>
              <span class="mt-1 block text-cantina-muted text-sm">{{ t('register.chooseByScanAndOrder') }}</span>
            </span>
          </button>
          <button
            type="button"
            class="card-cantina group relative overflow-hidden rounded-xl border-2 border-cantina-amber/50 px-6 py-8 text-left transition hover:border-cantina-amber focus:outline-none focus:ring-2 focus:ring-cantina-amber"
            @click="chooseNew"
          >
            <span class="absolute inset-0 bg-gradient-to-br from-cantina-amber/10 to-transparent pointer-events-none" />
            <span class="relative block">
              <span class="text-cantina-amber text-xs uppercase tracking-widest font-mono">{{ t('register.primaryCalibration') }}</span>
              <span class="mt-2 block text-lg md:text-xl text-cantina-cream font-mono">{{ t('register.notInSystem') }}</span>
              <span class="mt-1 block text-cantina-muted text-sm">{{ t('register.registrationAndScan') }}</span>
            </span>
          </button>
        </div>
      </div>

      <!-- Уже был: поиск по имени + выбор по аватарке -->
      <div v-else-if="step === 0 && landingChoice === 'returning'" class="space-y-6">
        <button
          type="button"
          class="btn-cantina-ghost text-sm font-mono"
          @click="backToLanding"
        >
          ← {{ t('register.otherStatus') }}
        </button>
        <p class="text-cantina-sand text-sm uppercase tracking-widest font-mono">{{ t('register.identificationByRegistry') }}</p>
        <h2 class="font-display text-xl text-cantina-cream font-semibold">{{ t('register.findByNameOrScans') }}</h2>
        <input
          v-model="returningSearchQuery"
          type="text"
          :placeholder="t('register.searchByCallsign')"
          class="w-full px-4 py-3 bg-cantina-surface border border-cantina-border rounded-lg text-cantina-cream placeholder-cantina-muted font-mono uppercase tracking-wider focus:outline-none focus:ring-2 focus:ring-cantina-copper focus:border-cantina-copper"
        />
        <div v-if="isLoadingRecentGuests" class="flex flex-col items-center justify-center py-12 gap-4">
          <div class="w-10 h-10 border-2 border-cantina-border border-t-cantina-copper rounded-full animate-spin" />
          <span class="text-sm text-cantina-muted font-mono">{{ t('register.loadingRegistry') }}</span>
        </div>
        <div v-else-if="filteredGuestsForReturning.length" class="flex flex-wrap gap-3">
          <button
            v-for="g in filteredGuestsForReturning"
            :key="g.id"
            type="button"
            class="card-cantina flex flex-col items-center gap-1.5 p-3 hover:border-cantina-copper transition focus:outline-none focus:ring-2 focus:ring-cantina-copper"
            @click="selectExistingGuest(g)"
          >
            <div class="w-14 h-14 rounded-full bg-cantina-surface overflow-hidden flex-shrink-0 border border-cantina-border">
              <img
                v-if="g.avatar_url"
                :src="g.avatar_url"
                :alt="g.callsign"
                class="w-full h-full object-cover"
              />
              <div v-else class="w-full h-full flex items-center justify-center text-lg font-mono text-cantina-muted">
                {{ (g.callsign || '?').slice(0, 2) }}
              </div>
            </div>
            <span class="text-xs font-mono text-cantina-cream uppercase max-w-[4.5rem] truncate">{{ g.callsign }}</span>
          </button>
        </div>
        <p v-else-if="!isLoadingRecentGuests" class="text-cantina-muted text-sm">{{ t('register.noOneFound') }}</p>
      </div>

      <!-- Карточка выбранного гостя: вся информация + заказы + кнопка «Заказать напиток» -->
      <div v-else-if="step === 2 && selectedExistingGuest && showGuestDetailView" class="space-y-6 relative">
        <div
          v-if="isLoadingGuestDetail || isLoadingOrderFlow"
          class="absolute inset-0 bg-cantina-bg/80 backdrop-blur-sm rounded-xl flex flex-col items-center justify-center gap-4 z-10 min-h-[200px]"
        >
          <div class="w-10 h-10 border-2 border-cantina-border border-t-cantina-copper rounded-full animate-spin" />
          <span class="text-sm text-cantina-sand font-mono">
            {{ isLoadingGuestDetail ? t('register.loadingData') : t('register.matchingDrink') }}
          </span>
        </div>
        <button
          type="button"
          class="btn-cantina-ghost text-sm font-mono flex items-center gap-1"
          @click="backToRegisterList"
        >
          ← {{ t('register.backToBooth') }}
        </button>
        <GuestCard
          :guest="{
            ...selectedExistingGuest,
            allergies: Array.isArray(selectedExistingGuest.allergies) ? selectedExistingGuest.allergies : (selectedExistingGuest.allergies ? [selectedExistingGuest.allergies] : []),
          }"
        />
        <div v-if="guestOrders.length" class="space-y-3">
          <h2 class="text-cantina-sand text-sm uppercase tracking-widest font-mono">{{ t('register.orderedBefore') }}</h2>
          <div class="grid grid-cols-3 sm:grid-cols-4 gap-3">
            <div
              v-for="order in guestOrders"
              :key="order.id"
              class="card-cantina overflow-hidden flex flex-col p-0"
            >
              <div class="aspect-square bg-cantina-surface relative">
                <img
                  v-if="order.image_url"
                  :src="order.image_url"
                  :alt="order.coffee_name"
                  class="w-full h-full object-cover"
                />
                <div
                  v-else
                  class="w-full h-full flex items-center justify-center text-2xl font-mono text-cantina-muted"
                >
                  {{ (order.coffee_name || '?').slice(0, 1) }}
                </div>
              </div>
              <div class="p-2 flex-1 min-w-0">
                <div class="text-xs font-mono text-cantina-cream uppercase truncate" :title="order.coffee_name">
                  {{ order.coffee_name }}
                </div>
                <div v-if="order.description" class="text-[10px] text-cantina-muted truncate">
                  {{ order.description }}
                </div>
                <div class="text-[10px] text-cantina-muted mt-0.5">
                  {{ order.status === 'picked_up' ? t('register.pickedUp') : order.status === 'ready' ? t('register.ready') : t('register.inQueue') }}
                </div>
              </div>
            </div>
          </div>
        </div>
        <p v-else class="text-cantina-muted text-sm">{{ t('register.notOrderedYet') }}</p>
        <button
          type="button"
          class="btn-cantina-primary w-full py-4 font-mono text-lg uppercase tracking-wider flex items-center justify-center gap-2 disabled:opacity-70"
          :disabled="isLoadingOrderFlow"
          @click="startOrderFlowForExistingGuest"
        >
          <span v-if="isLoadingOrderFlow" class="w-5 h-5 border-2 border-cantina-cream/30 border-t-cantina-cream rounded-full animate-spin flex-shrink-0" />
          <span>{{ isLoadingOrderFlow ? t('register.matching') : t('register.orderNewDrink') }}</span>
        </button>
      </div>

      <!-- Step 1: после фото — ввод позывного (только для новой регистрации) -->
      <div v-else-if="step === 1 && landingChoice === 'new' && showCallsignAfterPhoto" class="space-y-6">
        <button
          type="button"
          class="btn-cantina-ghost text-sm font-mono"
          @click="showCallsignAfterPhoto = false"
        >
          ← {{ t('register.backToPhoto') }}
        </button>
        <p class="text-cantina-sand text-sm uppercase tracking-widest font-mono">{{ t('register.callsign') }}</p>
        <h2 class="font-display text-xl text-cantina-cream font-semibold">{{ t('register.callsignForRegistry') }}</h2>
        <input
          v-model="callsign"
          type="text"
          :placeholder="t('register.callsignPlaceholder')"
          class="w-full px-4 py-3 bg-cantina-surface border border-cantina-border rounded-lg text-cantina-cream placeholder-cantina-muted font-mono uppercase tracking-wider focus:outline-none focus:ring-2 focus:ring-cantina-copper"
          @keydown.enter="acceptCallsignAndContinue"
        />
        <p v-if="callsignError" class="text-cantina-danger text-sm">{{ callsignError }}</p>
        <button
          type="button"
          class="btn-cantina-primary w-full py-3 font-mono uppercase"
          @click="acceptCallsignAndContinue"
        >
          {{ t('register.continueMatching') }}
        </button>
      </div>

      <!-- Step 1: Photo — биометрический сканер -->
      <div v-else-if="step === 1" class="space-y-6">
        <button
          v-if="landingChoice === 'new'"
          type="button"
          class="btn-cantina-ghost text-sm font-mono"
          @click="step = 0; backToLanding()"
        >
          ← {{ t('register.otherStatus') }}
        </button>
        <p class="text-cantina-sand text-sm uppercase tracking-widest font-mono">{{ t('register.biometricSensor') }}</p>
        <h1 class="font-display text-xl text-cantina-cream font-semibold">{{ t('register.faceInFrame') }}</h1>

        <!-- Подсветка вокруг сканера -->
        <div class="scanner-outer p-4 sm:p-6 bg-cantina-cream/95 rounded-2xl shadow-cantina-lg max-w-sm mx-auto border border-cantina-border">
          <div class="relative bg-cantina-bg rounded-xl overflow-visible">
            <!-- Овал «голова + плечи» — рамка человека -->
            <div class="scanner-frame relative mx-auto w-[280px] h-[340px] rounded-[45%_45%_50%_50%] overflow-hidden border-4 border-cantina-copper/90 shadow-[inset_0_0_30px_rgba(0,0,0,0.5),0_0_0_2px_rgba(184,115,51,0.5)]">
              <video
                v-show="!photoDataUrl"
                ref="videoRef"
                autoplay
                playsinline
                muted
                class="absolute inset-0 w-full h-full object-cover scale-105"
              />
              <canvas ref="canvasRef" class="hidden" />
              <!-- Сканирующая линия -->
              <div
                v-if="!photoDataUrl && !scanCountdown"
                class="scan-line absolute left-0 right-0 h-1 bg-cantina-copper/80 shadow-[0_0_12px_2px_rgba(184,115,51,0.9)] pointer-events-none"
                style="animation: scanMove 2.2s ease-in-out infinite"
              />
              <!-- Оверлей обратного отсчёта -->
              <div
                v-if="scanCountdown > 0"
                class="absolute inset-0 flex items-center justify-center bg-cantina-bg/60 pointer-events-none"
              >
                <span class="text-8xl font-black text-cantina-copper drop-shadow-[0_0_20px_rgba(184,115,51,0.8)] animate-pulse">
                  {{ scanCountdown }}
                </span>
              </div>
              <!-- Результат фото в той же рамке -->
              <img
                v-if="photoDataUrl"
                :src="photoDataUrl"
                :alt="t('register.scan')"
                class="absolute inset-0 w-full h-full object-cover"
              />
            </div>
            <!-- Подпись под рамкой -->
            <p class="text-center text-cantina-muted text-xs py-2 font-mono">{{ t('register.placeInFrame') }}</p>
          </div>

          <div v-if="!photoDataUrl" class="mt-4 flex justify-center">
            <button
              type="button"
              class="btn-cantina-primary px-8 py-4 disabled:opacity-60 disabled:pointer-events-none font-mono font-semibold uppercase tracking-wider"
              :disabled="scanCountdown > 0"
              @click="capturePhoto"
            >
              {{ scanCountdown > 0 ? '…' : t('register.takePhoto') }}
            </button>
          </div>
        </div>

        <p class="text-cantina-muted text-xs">{{ t('register.afterPressCountdown') }}</p>
        <button
          type="button"
          class="btn-cantina-primary w-full py-3 font-mono flex items-center justify-center gap-2 disabled:opacity-70"
          :disabled="isLoadingNextStep || !photoDataUrl"
          @click="goAfterPhoto"
        >
          <span v-if="isLoadingNextStep" class="w-5 h-5 border-2 border-cantina-cream/30 border-t-cantina-cream rounded-full animate-spin flex-shrink-0" />
          <span>{{ isLoadingNextStep ? t('register.loading') : t('register.next') }}</span>
        </button>
      </div>

      <!-- Step 2: Quiz (вопросы из БД) -->
      <div v-else-if="step === 2 && showQuiz && getCurrentQuizQuestion()" class="space-y-6">
        <p class="text-cantina-sand text-sm uppercase tracking-widest font-mono">{{ t('register.quizStep', { n: quizStep + 1, total: quizQuestions.length }) }}</p>
        <h2 class="text-lg font-mono text-cantina-sand">{{ getCurrentQuizQuestion().text }}</h2>
        <div class="space-y-3">
          <label
            v-for="a in getCurrentQuizQuestion().quiz_answers"
            :key="a.id"
            class="block p-4 rounded-lg border cursor-pointer transition card-cantina"
            :class="selectedQuizAnswerId === a.id
              ? 'border-cantina-copper bg-cantina-copper/20 text-cantina-cream'
              : 'border-cantina-border text-cantina-cream hover:border-cantina-border-light'"
          >
            <input
              type="radio"
              :name="'quiz-' + getCurrentQuizQuestion().id"
              :value="a.id"
              :checked="selectedQuizAnswerId === a.id"
              class="sr-only"
              @change="selectQuizAnswer(a)"
            />
            <span class="font-mono">▢ {{ a.text }}</span>
          </label>
        </div>
        <button
          type="button"
          class="btn-cantina-primary w-full py-3 font-mono"
          :disabled="selectedQuizAnswerId === null"
          @click="nextQuizQuestion"
        >
          {{ t('register.nextQuestion') }}
        </button>
      </div>

      <!-- Step 2: Аллергии (крупно в конце опросника) -->
      <div v-else-if="step === 2 && showAllergiesStep" class="space-y-6">
        <p class="text-cantina-sand text-sm uppercase tracking-widest font-mono">{{ t('register.matching') }}</p>
        <h2 class="font-display text-2xl md:text-3xl font-semibold text-cantina-amber text-center leading-tight">
          {{ t('register.allergiesIntro') }}
        </h2>
        <p class="text-cantina-muted text-center text-sm">{{ t('register.weWontOffer') }}</p>
        <div class="grid gap-3 py-2">
          <label
            v-for="a in allergensList"
            :key="a.id"
            class="flex items-center gap-4 p-4 rounded-xl border cursor-pointer transition text-lg card-cantina"
            :class="selectedAllergenLabels.includes(a.label)
              ? 'border-cantina-amber bg-cantina-amber/20 text-cantina-cream'
              : 'border-cantina-border text-cantina-cream hover:border-cantina-border-light'"
          >
            <input
              type="checkbox"
              :checked="selectedAllergenLabels.includes(a.label)"
              class="w-5 h-5 rounded border-cantina-border text-cantina-amber focus:ring-cantina-copper"
              @change="toggleAllergen(a.label)"
            />
            <span class="font-mono">☐ {{ a.label }}</span>
          </label>
        </div>
        <div class="space-y-1">
          <label class="block text-sm text-cantina-muted">{{ t('register.otherAllergies') }}</label>
          <input
            v-model="allergiesExtraInput"
            type="text"
            :placeholder="t('register.otherAllergiesPlaceholder')"
            class="w-full px-3 py-2 bg-cantina-surface border border-cantina-border rounded-lg text-cantina-cream placeholder-cantina-muted text-sm focus:outline-none focus:ring-2 focus:ring-cantina-copper"
          />
        </div>
        <button
          type="button"
          class="btn-cantina-primary w-full py-4 font-mono text-lg"
          @click="confirmAllergiesStep"
        >
          {{ t('register.nextResult') }}
        </button>
      </div>

      <!-- Step 2: Корректировка 4 параметров перед подбором напитка -->
      <div v-else-if="step === 2 && showProfileAdjustStep" class="space-y-6">
        <p class="text-cantina-sand text-sm uppercase tracking-widest font-mono">{{ t('register.matching') }}</p>
        <h2 class="font-display text-xl md:text-2xl font-semibold text-cantina-cream leading-tight">
          {{ t('register.profileTitle') }}
        </h2>
        <p class="text-cantina-muted text-sm">{{ t('register.profileAdjustHint') }}</p>
        <div class="space-y-5">
          <div>
            <div class="flex justify-between items-center mb-1">
              <span class="text-cantina-sand font-mono text-sm">{{ t('register.sweetness') }}</span>
              <span class="font-mono text-cantina-amber">{{ editableProfile.sweetness }}</span>
            </div>
            <input
              v-model.number="editableProfile.sweetness"
              type="range"
              min="0"
              max="10"
              class="w-full h-2 rounded-full appearance-none bg-cantina-surface accent-cantina-amber"
            />
          </div>
          <div>
            <div class="flex justify-between items-center mb-1">
              <span class="text-cantina-sand font-mono text-sm">{{ t('register.bitterness') }}</span>
              <span class="font-mono text-cantina-amber">{{ editableProfile.bitterness }}</span>
            </div>
            <div class="w-full h-2 rounded-full bg-cantina-surface overflow-hidden">
              <div
                class="h-full rounded-full bg-cantina-copper/80 transition-all"
                :style="{ width: (editableProfile.bitterness / 10) * 100 + '%' }"
              />
            </div>
          </div>
          <div>
            <div class="flex justify-between items-center mb-1">
              <span class="text-cantina-sand font-mono text-sm">{{ t('register.intensity') }}</span>
              <span class="font-mono text-cantina-amber">{{ editableProfile.intensity }}</span>
            </div>
            <div class="w-full h-2 rounded-full bg-cantina-surface overflow-hidden">
              <div
                class="h-full rounded-full bg-cantina-copper-light/80 transition-all"
                :style="{ width: (editableProfile.intensity / 10) * 100 + '%' }"
              />
            </div>
          </div>
          <div>
            <div class="flex justify-between items-center mb-1">
              <span class="text-cantina-sand font-mono text-sm">{{ t('register.extremeness') }}</span>
              <span class="font-mono text-cantina-amber">{{ editableProfile.extremeness }}</span>
            </div>
            <input
              v-model.number="editableProfile.extremeness"
              type="range"
              min="0"
              max="10"
              class="w-full h-2 rounded-full appearance-none bg-cantina-surface accent-cantina-copper"
            />
          </div>
        </div>
        <button
          type="button"
          class="btn-cantina-primary w-full py-4 font-mono text-lg uppercase tracking-wider"
          @click="confirmProfileAndContinue"
        >
          {{ selectedExistingGuest ? t('register.confirmProfileExisting') : t('register.confirmProfileNew') }}
        </button>
      </div>

      <!-- Step 2: Result (после квиза и аллергий) -->
      <div v-else-if="step === 2 && result" class="space-y-6">
        <p v-if="callsignError" class="text-cantina-danger font-mono text-sm">{{ callsignError }}</p>
        <p class="text-cantina-success">{{ t('register.profileAnalyzed') }}</p>
        <div class="space-y-1">
          <label class="block text-sm text-cantina-muted">{{ t('register.allergiesLabel') }}</label>
          <input
            v-model="allergiesInput"
            type="text"
            :placeholder="t('register.allergiesPlaceholder')"
            class="w-full px-3 py-2 bg-cantina-surface border border-cantina-border rounded-lg text-cantina-cream placeholder-cantina-muted text-sm focus:outline-none focus:ring-2 focus:ring-cantina-copper"
          />
        </div>
        <p class="text-cantina-muted text-sm">{{ t('register.drinkByProfile') }}</p>
        <GuestCard
          :guest="{
            callsign: selectedExistingGuest?.callsign || (callsign.trim().toUpperCase() || t('register.newGuest')),
            avatar_url: photoDataUrl || selectedExistingGuest?.avatar_url,
            allergies: parseAllergies(allergiesInput),
          }"
        />
        <template v-if="selectedExistingGuest">
          <button
            type="button"
            class="btn-cantina-secondary w-full py-3 font-mono flex items-center justify-center gap-2 disabled:opacity-70"
            :disabled="isFinishingExisting"
            @click="finishAsExistingGuest"
          >
            <span v-if="isFinishingExisting" class="w-5 h-5 border-2 border-cantina-cream/30 border-t-cantina-cream rounded-full animate-spin flex-shrink-0" />
            <span>{{ isFinishingExisting ? t('register.saving') : t('register.doneBackToBooth') }}</span>
          </button>
        </template>
        <button
          v-else
          type="button"
          class="btn-cantina-primary w-full py-3 font-mono flex items-center justify-center gap-2 disabled:opacity-70"
          :disabled="isSubmitting"
          @click="submitRegistration"
        >
          <span v-if="isSubmitting" class="w-5 h-5 border-2 border-cantina-cream/30 border-t-cantina-cream rounded-full animate-spin flex-shrink-0" />
          <span>{{ isSubmitting ? t('register.saving') : t('register.finishRegistration') }}</span>
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
@keyframes scanMove {
  0%, 100% { top: 8%; opacity: 1; }
  50% { top: 92%; opacity: 0.85; }
}
.scan-line {
  top: 8%;
}
</style>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import {
  getQuestionsWithAnswers,
  createQuestion,
  updateQuestion,
  deleteQuestion,
  createAnswer,
  updateAnswer,
  deleteAnswer,
} from '@/api/questions'

const questions = ref([])
const loading = ref(true)
const savingQuestionId = ref(null)
const savingAnswerId = ref(null)
const expandedId = ref(null)
const showNewQuestion = ref(false)
const newQuestion = ref({ text: '', weight: 1, is_active: true, is_galaxy_watcher: false })
const editQuestionDraft = ref({})
const newAnswerDraft = ref({}) // { questionId, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta }
const editAnswerDraft = ref({})
const selectedQuestionIds = ref([])
const deletingQuestionsBulk = ref(false)
/** По вопросу: массив id выбранных ответов для удаления */
const selectedAnswerIdsByQuestion = ref({})
const deletingAnswersBulk = ref(false)
const focusedQuestionIndex = ref(-1)

const QUESTIONS_PER_SESSION = 5

async function load() {
  loading.value = true
  try {
    questions.value = await getQuestionsWithAnswers(false)
  } finally {
    loading.value = false
  }
}

function startEditQuestion(q) {
  expandedId.value = q.id
  editQuestionDraft.value = {
    text: q.text,
    weight: Number(q.weight ?? 1),
    is_active: q.is_active !== false,
    is_galaxy_watcher: q.is_galaxy_watcher === true,
  }
}

function cancelEditQuestion() {
  editQuestionDraft.value = {}
}

function startAddAnswer(questionId) {
  newAnswerDraft.value = {
    questionId,
    text: '',
    sweetness_delta: 0,
    bitterness_delta: 0,
    intensity_delta: 0,
    extremeness_delta: 0,
  }
}

function startEditAnswer(a) {
  editAnswerDraft.value = {
    id: a.id,
    text: a.text,
    sweetness_delta: a.sweetness_delta ?? 0,
    bitterness_delta: a.bitterness_delta ?? 0,
    intensity_delta: a.intensity_delta ?? 0,
    extremeness_delta: a.extremeness_delta ?? 0,
  }
}

function cancelEditAnswer() {
  editAnswerDraft.value = {}
}

function cancelNewAnswer() {
  newAnswerDraft.value = {}
}

async function saveQuestion(id) {
  if (savingQuestionId.value) return
  savingQuestionId.value = id
  try {
    if (id) {
      await updateQuestion(id, editQuestionDraft.value)
      cancelEditQuestion()
    } else {
      await createQuestion(newQuestion.value)
      showNewQuestion.value = false
      newQuestion.value = { text: '', weight: 1, is_active: true, is_galaxy_watcher: false }
    }
    await load()
  } catch (e) {
    alert(e?.message || 'Ошибка')
  } finally {
    savingQuestionId.value = null
  }
}

function toggleQuestionSelect(id) {
  if (selectedQuestionIds.value.includes(id)) {
    selectedQuestionIds.value = selectedQuestionIds.value.filter((x) => x !== id)
  } else {
    selectedQuestionIds.value = [...selectedQuestionIds.value, id]
  }
}

function selectAllQuestions() {
  selectedQuestionIds.value = questions.value.map((q) => q.id)
}

function clearQuestionSelection() {
  selectedQuestionIds.value = []
}

async function removeSelectedQuestions() {
  if (!selectedQuestionIds.value.length) return
  deletingQuestionsBulk.value = true
  try {
    for (const id of selectedQuestionIds.value) {
      await deleteQuestion(id)
    }
    if (expandedId.value && selectedQuestionIds.value.includes(expandedId.value)) expandedId.value = null
    clearQuestionSelection()
    await load()
  } catch (e) {
    alert(e?.message || 'Ошибка')
  } finally {
    deletingQuestionsBulk.value = false
  }
}

async function removeQuestion(id) {
  if (!confirm('Удалить вопрос и все ответы?')) return
  try {
    await deleteQuestion(id)
    await load()
    if (expandedId.value === id) expandedId.value = null
  } catch (e) {
    alert(e?.message || 'Ошибка')
  }
}

function toggleQuestionActive(q) {
  updateQuestion(q.id, { is_active: !q.is_active }).then(() => load()).catch((e) => alert(e?.message))
}

async function saveAnswer(questionId, answerId) {
  if (savingAnswerId.value) return
  savingAnswerId.value = answerId ?? 'new'
  try {
    if (answerId) {
      await updateAnswer(answerId, {
        text: editAnswerDraft.value.text,
        sweetness_delta: editAnswerDraft.value.sweetness_delta,
        bitterness_delta: editAnswerDraft.value.bitterness_delta,
        intensity_delta: editAnswerDraft.value.intensity_delta,
        extremeness_delta: editAnswerDraft.value.extremeness_delta,
      })
      cancelEditAnswer()
    } else {
      const d = newAnswerDraft.value
      if (d.questionId !== questionId) return
      await createAnswer(questionId, {
        text: d.text,
        sweetness_delta: d.sweetness_delta,
        bitterness_delta: d.bitterness_delta,
        intensity_delta: d.intensity_delta,
        extremeness_delta: d.extremeness_delta,
      })
      cancelNewAnswer()
    }
    await load()
  } catch (e) {
    alert(e?.message || 'Ошибка')
  } finally {
    savingAnswerId.value = null
  }
}

function toggleAnswerSelect(questionId, answerId) {
  const key = questionId
  const arr = selectedAnswerIdsByQuestion.value[key] || []
  if (arr.includes(answerId)) {
    selectedAnswerIdsByQuestion.value = {
      ...selectedAnswerIdsByQuestion.value,
      [key]: arr.filter((x) => x !== answerId),
    }
  } else {
    selectedAnswerIdsByQuestion.value = {
      ...selectedAnswerIdsByQuestion.value,
      [key]: [...arr, answerId],
    }
  }
}

function getSelectedAnswers(questionId) {
  return selectedAnswerIdsByQuestion.value[questionId] || []
}

function selectAllAnswersInQuestion(questionId) {
  const q = questions.value.find((qu) => qu.id === questionId)
  const ids = (q?.quiz_answers || []).map((a) => a.id)
  selectedAnswerIdsByQuestion.value = {
    ...selectedAnswerIdsByQuestion.value,
    [questionId]: ids,
  }
}

function clearAnswerSelection(questionId) {
  const next = { ...selectedAnswerIdsByQuestion.value }
  delete next[questionId]
  selectedAnswerIdsByQuestion.value = next
}

async function removeSelectedAnswers(questionId) {
  const ids = getSelectedAnswers(questionId)
  if (!ids.length) return
  deletingAnswersBulk.value = true
  try {
    for (const id of ids) {
      await deleteAnswer(id)
    }
    clearAnswerSelection(questionId)
    await load()
  } catch (e) {
    alert(e?.message || 'Ошибка')
  } finally {
    deletingAnswersBulk.value = false
  }
}

async function removeAnswer(id) {
  if (!confirm('Удалить ответ?')) return
  try {
    await deleteAnswer(id)
    await load()
    cancelEditAnswer()
  } catch (e) {
    alert(e?.message || 'Ошибка')
  }
}

function deltaStr(v) {
  const n = Number(v) ?? 0
  if (n > 0) return `+${n}`
  if (n < 0) return `${n}`
  return '0'
}

function handleKeydown(e) {
  const inInput = e.target.matches('input, textarea, select')
  if (e.key === 'Escape') {
    cancelEditQuestion()
    cancelEditAnswer()
    cancelNewAnswer()
    expandedId.value = null
    showNewQuestion.value = false
    if (inInput) return
  }
  if (inInput) return
  e.preventDefault()
  const list = questions.value
  if (e.key === 'ArrowUp') {
    focusedQuestionIndex.value = Math.max(-1, focusedQuestionIndex.value - 1)
    return
  }
  if (e.key === 'ArrowDown') {
    if (list.length) focusedQuestionIndex.value = Math.min(list.length - 1, focusedQuestionIndex.value + 1)
    return
  }
  if (e.key === 'Enter') {
    if (expandedId.value && editQuestionDraft.value.text !== undefined) {
      const q = list.find((qu) => qu.id === expandedId.value)
      if (q) saveQuestion(q.id)
      return
    }
    if (showNewQuestion.value) {
      saveQuestion(null)
      return
    }
    if (focusedQuestionIndex.value >= 0 && focusedQuestionIndex.value < list.length) {
      const q = list[focusedQuestionIndex.value]
      startEditQuestion(q)
      expandedId.value = q.id
    }
  }
}

onMounted(() => {
  load()
  window.addEventListener('keydown', handleKeydown)
})
onUnmounted(() => {
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<template>
  <div class="min-h-screen bg-cantina-bg text-cantina-cream p-4 md:p-6 font-sans">
    <div class="max-w-4xl mx-auto">
      <div class="flex items-center justify-between gap-4 mb-6">
        <div>
          <h1 class="font-display text-2xl text-cantina-amber">Вопросы для подбора напитков</h1>
          <p class="text-cantina-muted text-sm mt-1">
            Каждый ответ задаёт изменение по 4 параметрам (сладость, горечь, интенсивность, экстрим). На сессию показывается {{ QUESTIONS_PER_SESSION }} случайных активных вопросов; один из них всегда из рубрики «Смотрящий по галактике спрашивает» (если такие вопросы есть).
          </p>
        </div>
        <router-link to="/admin/edit" class="text-slate-400 hover:text-white text-sm">← Админ</router-link>
      </div>

      <div v-if="loading" class="text-cantina-muted py-8">Загрузка…</div>

      <div v-else class="space-y-4">
        <!-- Новый вопрос -->
        <div
          v-if="showNewQuestion"
          class="p-4 rounded-xl bg-cantina-card border border-cantina-copper/50 space-y-3"
        >
          <input
            v-model="newQuestion.text"
            type="text"
            placeholder="Текст вопроса"
            class="w-full px-3 py-2 bg-cantina-surface border border-cantina-border rounded text-cantina-cream placeholder-cantina-muted focus:ring-2 focus:ring-cantina-copper"
            @keydown.enter="saveQuestion(null)"
            @keydown.escape="showNewQuestion = false; newQuestion = { text: '', weight: 1, is_active: true, is_galaxy_watcher: false }"
          />
          <div class="flex gap-4 items-center">
            <label class="flex items-center gap-2">
              <span class="text-cantina-muted text-sm">Вес (weight)</span>
              <input
                v-model.number="newQuestion.weight"
                type="number"
                min="0"
                step="0.1"
                class="w-20 px-2 py-1 bg-cantina-surface border border-cantina-border rounded text-cantina-cream text-sm"
              />
            </label>
            <label class="flex items-center gap-2">
              <input v-model="newQuestion.is_active" type="checkbox" class="rounded accent-cantina-copper" />
              <span class="text-cantina-muted text-sm">Активен</span>
            </label>
            <label class="flex items-center gap-2" title="В каждом сете гостю будет показан ровно один такой вопрос">
              <input v-model="newQuestion.is_galaxy_watcher" type="checkbox" class="rounded accent-cantina-copper" />
              <span class="text-cantina-muted text-sm">Смотрящий по галактике спрашивает</span>
            </label>
          </div>
          <div class="flex gap-2">
            <button
              type="button"
              class="btn-cantina-primary p-2 rounded"
              :disabled="!newQuestion.text.trim() || savingQuestionId"
              :title="savingQuestionId ? 'Сохранение…' : 'Добавить вопрос'"
              @click="saveQuestion(null)"
            >
              <span v-if="savingQuestionId" class="material-icons animate-spin">hourglass_empty</span>
              <span v-else class="material-icons">add</span>
            </button>
            <button type="button" class="btn-cantina-secondary p-2 rounded" title="Отмена" @click="showNewQuestion = false; newQuestion = { text: '', weight: 1, is_active: true, is_galaxy_watcher: false }">
              <span class="material-icons">close</span>
            </button>
          </div>
        </div>

        <button
          v-if="!showNewQuestion"
          type="button"
          class="w-full py-2 border border-dashed border-cantina-border rounded-lg text-cantina-muted hover:border-cantina-copper hover:text-cantina-copper text-sm inline-flex items-center justify-center gap-2 transition-colors"
          title="Добавить вопрос"
          @click="showNewQuestion = true"
        >
          <span class="material-icons text-xl">add</span>
          <span>Добавить вопрос</span>
        </button>

        <!-- Панель массового удаления вопросов -->
        <div
          v-if="questions.length > 0"
          class="flex flex-wrap items-center gap-3 py-2"
        >
          <label class="flex items-center gap-2 cursor-pointer text-cantina-muted hover:text-cantina-cream text-sm">
            <input
              type="checkbox"
              :checked="questions.length > 0 && selectedQuestionIds.length === questions.length"
              :indeterminate="selectedQuestionIds.length > 0 && selectedQuestionIds.length < questions.length"
              class="rounded"
              @change="selectedQuestionIds.length === questions.length ? clearQuestionSelection() : selectAllQuestions()"
            />
            <span>Выбрать все вопросы ({{ questions.length }})</span>
          </label>
          <template v-if="selectedQuestionIds.length > 0">
            <button
              type="button"
              class="px-3 py-1.5 bg-red-600 hover:bg-red-500 disabled:opacity-60 text-white rounded text-sm inline-flex items-center gap-1.5"
              :disabled="deletingQuestionsBulk"
              :title="deletingQuestionsBulk ? 'Удаление…' : `Удалить выбранные (${selectedQuestionIds.length})`"
              @click="removeSelectedQuestions"
            >
              <span v-if="deletingQuestionsBulk" class="material-icons animate-spin text-lg">hourglass_empty</span>
              <span v-else class="material-icons text-lg">delete</span>
              <span>{{ deletingQuestionsBulk ? 'Удаление…' : `Удалить (${selectedQuestionIds.length})` }}</span>
            </button>
            <button
              type="button"
              class="btn-cantina-secondary px-3 py-1.5 rounded text-sm inline-flex items-center gap-1.5"
              title="Снять выбор"
              @click="clearQuestionSelection"
            >
              <span class="material-icons text-lg">clear</span>
              <span>Снять выбор</span>
            </button>
          </template>
        </div>

        <!-- Список вопросов -->
        <div
          v-for="(q, qIdx) in questions"
          :key="q.id"
          class="rounded-xl border overflow-hidden"
          :class="[
            q.is_active !== false ? 'bg-cantina-card border-cantina-border' : 'bg-cantina-card/60 border-cantina-border opacity-80',
            selectedQuestionIds.includes(q.id) ? 'ring-2 ring-cantina-amber/60' : '',
            focusedQuestionIndex === qIdx && expandedId !== q.id ? 'ring-2 ring-cantina-copper/50' : '',
          ]"
        >
          <div class="p-4">
            <div class="flex items-start gap-3 flex-wrap">
              <label class="flex items-center flex-shrink-0 cursor-pointer" title="Выбрать вопрос для удаления">
                <input
                  type="checkbox"
                  :checked="selectedQuestionIds.includes(q.id)"
                  class="w-4 h-4 rounded"
                  @change="toggleQuestionSelect(q.id)"
                />
              </label>
              <label class="flex items-center gap-2 cursor-pointer" title="Включить/выключить вопрос">
                <input type="checkbox" :checked="q.is_active !== false" class="w-4 h-4 rounded" @change="toggleQuestionActive(q)" />
                <span class="text-slate-500 text-xs">Вкл</span>
              </label>
              <div class="min-w-0 flex-1">
                <template v-if="expandedId === q.id && editQuestionDraft.text !== undefined">
                  <input
                    v-model="editQuestionDraft.text"
                    type="text"
                    class="w-full px-3 py-2 bg-cantina-surface border border-cantina-border rounded text-cantina-cream text-sm mb-2 focus:ring-2 focus:ring-cantina-copper"
                    @keydown.enter="saveQuestion(q.id)"
                    @keydown.escape="cancelEditQuestion(); expandedId = null"
                  />
                  <div class="flex gap-2 items-center flex-wrap">
                    <label class="flex items-center gap-1 text-xs">
                      <span class="text-slate-500">Вес</span>
                      <input
                        v-model.number="editQuestionDraft.weight"
                        type="number"
                        min="0"
                        step="0.1"
                        class="w-16 px-1 py-0.5 bg-slate-700 border border-slate-600 rounded text-white"
                      />
                    </label>
                    <label class="flex items-center gap-1 text-xs">
                      <input v-model="editQuestionDraft.is_galaxy_watcher" type="checkbox" class="rounded" />
                      <span class="text-cantina-muted">Смотрящий по галактике</span>
                    </label>
                    <button type="button" class="btn-cantina-primary p-1 rounded" :disabled="!!savingQuestionId" title="Сохранить" @click="saveQuestion(q.id)">
                      <span class="material-icons text-lg">save</span>
                    </button>
                    <button type="button" class="btn-cantina-secondary p-1 rounded" title="Отмена" @click="cancelEditQuestion(); expandedId = null">
                      <span class="material-icons text-lg">close</span>
                    </button>
                  </div>
                </template>
                <template v-else>
                  <p class="text-cantina-cream font-medium">{{ q.text }}</p>
                  <p class="text-cantina-muted text-xs mt-0.5">
                    Вес: {{ q.weight ?? 1 }}
                    <span v-if="q.is_galaxy_watcher" class="ml-2 text-cantina-amber/90">· Смотрящий по галактике</span>
                  </p>
                  <div class="flex gap-1 mt-1">
                    <button type="button" class="p-1 text-cantina-copper hover:text-cantina-copper-light rounded hover:bg-cantina-surface transition-colors" title="Изменить" @click="startEditQuestion(q); expandedId = q.id">
                      <span class="material-icons text-lg">edit</span>
                    </button>
                    <button type="button" class="p-1 text-cantina-danger hover:opacity-90 rounded hover:bg-cantina-surface transition-colors" title="Удалить" @click="removeQuestion(q.id)">
                      <span class="material-icons text-lg">delete</span>
                    </button>
                  </div>
                </template>
              </div>
            </div>

            <!-- Ответы: таблица -->
            <div class="mt-4 ml-6 border-l-2 border-slate-600 pl-4">
              <div class="flex flex-wrap items-center gap-2 mb-2">
                <p class="text-slate-500 text-xs">Ответы (влияние на параметры)</p>
                <template v-if="(q.quiz_answers || []).length > 0">
                  <label class="flex items-center gap-1 cursor-pointer text-cantina-muted hover:text-cantina-cream text-xs">
                    <input
                      type="checkbox"
                      :checked="getSelectedAnswers(q.id).length === (q.quiz_answers || []).length"
                      :indeterminate="getSelectedAnswers(q.id).length > 0 && getSelectedAnswers(q.id).length < (q.quiz_answers || []).length"
                      class="rounded"
                      @change="getSelectedAnswers(q.id).length === (q.quiz_answers || []).length ? clearAnswerSelection(q.id) : selectAllAnswersInQuestion(q.id)"
                    />
                    <span>все</span>
                  </label>
                  <template v-if="getSelectedAnswers(q.id).length > 0">
                    <button
                      type="button"
                      class="px-2 py-0.5 bg-red-600/80 hover:bg-red-500 disabled:opacity-60 text-white rounded text-xs inline-flex items-center gap-0.5"
                      :disabled="deletingAnswersBulk"
                      :title="deletingAnswersBulk ? '…' : `Удалить (${getSelectedAnswers(q.id).length})`"
                      @click="removeSelectedAnswers(q.id)"
                    >
                      <span v-if="deletingAnswersBulk" class="material-icons text-sm animate-spin">hourglass_empty</span>
                      <span v-else class="material-icons text-sm">delete</span>
                      <span>{{ deletingAnswersBulk ? '…' : `Удалить (${getSelectedAnswers(q.id).length})` }}</span>
                    </button>
                    <button
                      type="button"
                      class="btn-cantina-secondary px-2 py-0.5 rounded text-xs inline-flex items-center gap-0.5"
                      title="Снять выбор"
                      @click="clearAnswerSelection(q.id)"
                    >
                      <span class="material-icons text-sm">clear</span>
                      <span>Снять</span>
                    </button>
                  </template>
                </template>
              </div>
              <div class="overflow-x-auto">
                <table class="w-full text-sm border-collapse">
                  <thead>
                    <tr class="text-slate-400 border-b border-slate-600">
                      <th class="w-8 py-1 pr-1"></th>
                      <th class="text-left py-1 pr-2">Ответ</th>
                      <th class="text-center py-1 px-1 w-14">Sweet</th>
                      <th class="text-center py-1 px-1 w-14">Bitter</th>
                      <th class="text-center py-1 px-1 w-14">Intense</th>
                      <th class="text-center py-1 px-1 w-14">Extreme</th>
                      <th class="w-20"></th>
                    </tr>
                  </thead>
                  <tbody>
                    <!-- Новая строка ответа -->
                    <tr v-if="newAnswerDraft.questionId === q.id" class="border-b border-cantina-border/50">
                      <td class="py-1 pr-1 w-8"></td>
                      <td class="py-1 pr-2">
                        <input
                          v-model="newAnswerDraft.text"
                          type="text"
                          placeholder="Текст ответа"
                          class="w-full px-2 py-1 bg-slate-700 border border-slate-600 rounded text-white text-xs"
                          @keydown.enter="saveAnswer(q.id, null)"
                          @keydown.escape="cancelNewAnswer"
                        />
                      </td>
                      <td class="px-1">
                        <input
                          v-model.number="newAnswerDraft.sweetness_delta"
                          type="number"
                          min="-3"
                          max="3"
                          class="w-12 px-1 py-0.5 bg-cantina-surface border border-cantina-border rounded text-cantina-cream text-center text-xs"
                        />
                      </td>
                      <td class="px-1">
                        <input
                          v-model.number="newAnswerDraft.bitterness_delta"
                          type="number"
                          min="-3"
                          max="3"
                          class="w-12 px-1 py-0.5 bg-cantina-surface border border-cantina-border rounded text-cantina-cream text-center text-xs"
                        />
                      </td>
                      <td class="px-1">
                        <input
                          v-model.number="newAnswerDraft.intensity_delta"
                          type="number"
                          min="-3"
                          max="3"
                          class="w-12 px-1 py-0.5 bg-cantina-surface border border-cantina-border rounded text-cantina-cream text-center text-xs"
                        />
                      </td>
                      <td class="px-1">
                        <input
                          v-model.number="newAnswerDraft.extremeness_delta"
                          type="number"
                          min="-3"
                          max="5"
                          class="w-12 px-1 py-0.5 bg-cantina-surface border border-cantina-border rounded text-cantina-cream text-center text-xs"
                        />
                      </td>
                      <td class="py-1">
                        <button type="button" class="p-0.5 text-cyan-400 rounded hover:bg-slate-700" :disabled="!newAnswerDraft.text.trim() || savingAnswerId" title="Сохранить" @click="saveAnswer(q.id, null)">
                          <span class="material-icons text-base">check</span>
                        </button>
                        <button type="button" class="p-0.5 text-cantina-muted rounded hover:bg-cantina-surface" title="Отмена" @click="cancelNewAnswer">
                          <span class="material-icons text-base">close</span>
                        </button>
                      </td>
                    </tr>
                    <tr
                      v-for="a in (q.quiz_answers || [])"
                      :key="a.id"
                      class="border-b border-cantina-border/50"
                      :class="{ 'bg-red-900/20': getSelectedAnswers(q.id).includes(a.id) }"
                    >
                      <td class="py-1 pr-1 w-8">
                        <label class="cursor-pointer flex items-center justify-center">
                          <input
                            type="checkbox"
                            :checked="getSelectedAnswers(q.id).includes(a.id)"
                            class="rounded w-3.5 h-3.5"
                            @change="toggleAnswerSelect(q.id, a.id)"
                          />
                        </label>
                      </td>
                      <td class="py-1 pr-2">
                        <template v-if="editAnswerDraft.id === a.id">
                          <input
                            v-model="editAnswerDraft.text"
                            type="text"
                            class="w-full px-2 py-1 bg-slate-700 border border-slate-600 rounded text-white text-xs"
                            @keydown.enter="saveAnswer(q.id, a.id)"
                            @keydown.escape="cancelEditAnswer"
                          />
                        </template>
                        <span v-else class="text-slate-300">{{ a.text }}</span>
                      </td>
                      <td class="px-1 text-center">
                        <template v-if="editAnswerDraft.id === a.id">
                          <input
                            v-model.number="editAnswerDraft.sweetness_delta"
                            type="number"
                            min="-3"
                            max="3"
                            class="w-12 px-1 py-0.5 bg-cantina-surface border border-cantina-border rounded text-cantina-cream text-center text-xs"
                          />
                        </template>
                        <span v-else :class="(a.sweetness_delta || 0) >= 0 ? 'text-emerald-400' : 'text-rose-400'">{{ deltaStr(a.sweetness_delta) }}</span>
                      </td>
                      <td class="px-1 text-center">
                        <template v-if="editAnswerDraft.id === a.id">
                          <input
                            v-model.number="editAnswerDraft.bitterness_delta"
                            type="number"
                            min="-3"
                            max="3"
                            class="w-12 px-1 py-0.5 bg-cantina-surface border border-cantina-border rounded text-cantina-cream text-center text-xs"
                          />
                        </template>
                        <span v-else :class="(a.bitterness_delta || 0) >= 0 ? 'text-cantina-success' : 'text-cantina-danger'">{{ deltaStr(a.bitterness_delta) }}</span>
                      </td>
                      <td class="px-1 text-center">
                        <template v-if="editAnswerDraft.id === a.id">
                          <input
                            v-model.number="editAnswerDraft.intensity_delta"
                            type="number"
                            min="-3"
                            max="3"
                            class="w-12 px-1 py-0.5 bg-cantina-surface border border-cantina-border rounded text-cantina-cream text-center text-xs"
                          />
                        </template>
                        <span v-else :class="(a.intensity_delta || 0) >= 0 ? 'text-emerald-400' : 'text-rose-400'">{{ deltaStr(a.intensity_delta) }}</span>
                      </td>
                      <td class="px-1 text-center">
                        <template v-if="editAnswerDraft.id === a.id">
                          <input
                            v-model.number="editAnswerDraft.extremeness_delta"
                            type="number"
                            min="-3"
                            max="5"
                            class="w-12 px-1 py-0.5 bg-cantina-surface border border-cantina-border rounded text-cantina-cream text-center text-xs"
                          />
                        </template>
                        <span v-else :class="(a.extremeness_delta || 0) >= 0 ? 'text-cantina-amber' : 'text-cantina-danger'">{{ deltaStr(a.extremeness_delta) }}</span>
                      </td>
                      <td class="py-1">
                        <template v-if="editAnswerDraft.id === a.id">
                          <button type="button" class="p-0.5 text-cyan-400 rounded hover:bg-slate-700" :disabled="!!savingAnswerId" title="Сохранить" @click="saveAnswer(q.id, a.id)">
                            <span class="material-icons text-base">check</span>
                          </button>
                          <button type="button" class="p-0.5 text-cantina-muted rounded hover:bg-cantina-surface" title="Отмена" @click="cancelEditAnswer">
                            <span class="material-icons text-base">close</span>
                          </button>
                        </template>
                        <template v-else>
                          <button type="button" class="p-0.5 text-cyan-400 rounded hover:bg-slate-700" title="Изменить" @click="startEditAnswer(a)">
                            <span class="material-icons text-base">edit</span>
                          </button>
                          <button type="button" class="p-0.5 text-red-400/80 rounded hover:bg-slate-700" title="Удалить" @click="removeAnswer(a.id)">
                            <span class="material-icons text-base">delete</span>
                          </button>
                        </template>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <button
                v-if="newAnswerDraft.questionId !== q.id"
                type="button"
                class="mt-2 text-cantina-muted hover:text-cantina-copper text-xs inline-flex items-center gap-1 transition-colors"
                title="Добавить ответ"
                @click="startAddAnswer(q.id)"
              >
                <span class="material-icons text-base">add</span>
                <span>Добавить ответ</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

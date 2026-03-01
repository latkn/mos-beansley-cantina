<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import {
  getAllTamadaTasks,
  createTamadaTask,
  updateTamadaTask,
  deleteTamadaTask,
} from '@/api/tamadaTasks'

const tasks = ref([])
const loading = ref(true)
const savingId = ref(null)
const showNew = ref(false)
const newTaskText = ref('')
const newTaskDifficulty = ref(3)
const editDraft = ref({})
const focusedIndex = ref(-1)

const DIFFICULTY_LABELS = {
  1: '1 — лёгкое',
  2: '2 — ниже среднего',
  3: '3 — среднее',
  4: '4 — выше среднего',
  5: '5 — сложное',
}

async function load() {
  loading.value = true
  try {
    tasks.value = await getAllTamadaTasks()
  } finally {
    loading.value = false
  }
}

function startEdit(item) {
  editDraft.value = {
    id: item.id,
    task_text: item.task_text,
    difficulty: item.difficulty != null ? item.difficulty : 3,
  }
}

function cancelEdit() {
  editDraft.value = {}
}

async function saveItem(id) {
  if (savingId.value) return
  savingId.value = id
  try {
    if (editDraft.value.id) {
      await updateTamadaTask(editDraft.value.id, {
        task_text: editDraft.value.task_text,
        difficulty: editDraft.value.difficulty,
      })
      cancelEdit()
    } else {
      await createTamadaTask({
        task_text: newTaskText.value.trim(),
        sort_order: tasks.value.length,
        difficulty: newTaskDifficulty.value,
      })
      showNew.value = false
      newTaskText.value = ''
      newTaskDifficulty.value = 3
    }
    await load()
  } catch (e) {
    alert(e?.message || 'Ошибка')
  } finally {
    savingId.value = null
  }
}

async function remove(id) {
  if (!confirm('Удалить задание из списка?')) return
  try {
    await deleteTamadaTask(id)
    await load()
    if (editDraft.value.id === id) cancelEdit()
  } catch (e) {
    alert(e?.message || 'Ошибка')
  }
}

function handleKeydown(e) {
  const inInput = e.target.matches('input, textarea, select')
  if (e.key === 'Escape') {
    cancelEdit()
    showNew.value = false
    newTaskText.value = ''
    if (inInput) return
  }
  if (inInput) return
  e.preventDefault()
  const list = tasks.value
  if (e.key === 'ArrowUp') {
    focusedIndex.value = Math.max(-1, focusedIndex.value - 1)
    return
  }
  if (e.key === 'ArrowDown') {
    if (list.length) focusedIndex.value = Math.min(list.length - 1, focusedIndex.value + 1)
    return
  }
  if (e.key === 'Enter' && editDraft.value.id) {
    saveItem(editDraft.value.id)
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
    <div class="max-w-2xl mx-auto">
      <div class="flex items-center justify-between gap-4 mb-6">
        <h1 class="font-display text-2xl text-cantina-amber">Задания штаба</h1>
        <router-link to="/admin/edit" class="text-cantina-sand hover:text-cantina-cream text-sm transition-colors">← Админ</router-link>
      </div>

      <p class="text-cantina-muted text-sm mb-4">
        Эти задания показываются при «Объединить расу» и выводятся на табло. Редактируемый список центра управления заданиями. Рекомендуется заканчивать фразой про фотоотчёт.
      </p>
      <p class="text-cantina-muted text-xs mb-4">
        Сложность 1–5: чем выше рейтинг гостей (готовность к экспериментальным/острым напиткам), тем сложнее задание можно выдавать. Пока подбор по сложности не включён — будет использоваться при авто-запуске по расе.
      </p>

      <div v-if="loading" class="text-cantina-muted">Загрузка…</div>

      <ul v-else class="space-y-2">
        <li
          v-for="(item, idx) in tasks"
          :key="item.id"
          class="rounded-lg border border-cantina-border bg-cantina-card p-3"
          :class="{ 'ring-2 ring-cantina-copper/50': focusedIndex === idx && !editDraft.id }"
        >
          <span class="text-cantina-muted w-6 inline-block">{{ idx + 1 }}.</span>
          <template v-if="editDraft.id === item.id">
            <textarea
              v-model="editDraft.task_text"
              rows="3"
              class="w-full mt-1 px-3 py-2 bg-cantina-surface border border-cantina-border rounded text-cantina-cream text-sm focus:ring-2 focus:ring-cantina-copper"
              @keydown.enter.prevent="saveItem(item.id)"
              @keydown.escape="cancelEdit"
            />
            <div class="mt-2 flex items-center gap-3">
              <label class="text-cantina-muted text-sm shrink-0">Сложность:</label>
              <input
                v-model.number="editDraft.difficulty"
                type="range"
                min="1"
                max="5"
                class="accent-cantina-copper flex-1 max-w-[140px]"
              />
              <span class="text-cantina-sand text-sm w-40">{{ DIFFICULTY_LABELS[editDraft.difficulty] ?? editDraft.difficulty }}</span>
            </div>
            <div class="mt-2 flex gap-2">
              <button
                type="button"
                class="btn-cantina-primary p-1.5 rounded text-sm"
                :disabled="savingId === item.id"
                @click="saveItem(item.id)"
              >
                <span v-if="savingId === item.id" class="material-icons animate-spin text-lg">hourglass_empty</span>
                <span v-else class="material-icons text-lg">save</span>
              </button>
              <button
                type="button"
                class="btn-cantina-secondary p-1.5 rounded text-sm"
                @click="cancelEdit"
              >
                <span class="material-icons text-lg">close</span>
              </button>
            </div>
          </template>
          <template v-else>
            <span class="text-cantina-cream text-sm">{{ item.task_text }}</span>
            <div class="mt-1 text-cantina-muted text-xs">
              Сложность: {{ item.difficulty != null ? DIFFICULTY_LABELS[item.difficulty] : '3 — среднее' }}
            </div>
            <div class="mt-2 flex gap-1">
              <button
                type="button"
                class="p-1.5 text-cantina-copper hover:text-cantina-copper-light rounded hover:bg-cantina-surface text-sm transition-colors"
                title="Изменить"
                @click="startEdit(item)"
              >
                <span class="material-icons text-lg">edit</span>
              </button>
              <button
                type="button"
                class="p-1.5 text-cantina-danger hover:opacity-90 rounded hover:bg-cantina-surface text-sm transition-colors"
                title="Удалить"
                @click="remove(item.id)"
              >
                <span class="material-icons text-lg">delete</span>
              </button>
            </div>
          </template>
        </li>
      </ul>

      <div v-if="showNew" class="mt-4 p-4 rounded-lg border border-cantina-border bg-cantina-card">
        <textarea
          v-model="newTaskText"
          rows="3"
          placeholder="Текст задания (например: Изобразить рождение сверхновой. Фотоотчёт обязателен.)"
          class="w-full px-3 py-2 bg-cantina-surface border border-cantina-border rounded text-cantina-cream text-sm focus:ring-2 focus:ring-cantina-copper"
          @keydown.escape="showNew = false; newTaskText = ''"
        />
        <div class="mt-2 flex items-center gap-3">
          <label class="text-cantina-muted text-sm shrink-0">Сложность:</label>
          <input
            v-model.number="newTaskDifficulty"
            type="range"
            min="1"
            max="5"
            class="accent-cantina-copper flex-1 max-w-[140px]"
          />
          <span class="text-cantina-sand text-sm w-40">{{ DIFFICULTY_LABELS[newTaskDifficulty] }}</span>
        </div>
        <div class="mt-2 flex gap-2">
          <button
            type="button"
            class="btn-cantina-primary p-2 rounded text-sm"
            :disabled="!newTaskText.trim() || savingId"
            @click="saveItem(null)"
          >
            <span v-if="savingId" class="material-icons animate-spin">hourglass_empty</span>
            <span v-else class="material-icons">add</span>
            Добавить
          </button>
          <button
            type="button"
            class="btn-cantina-secondary p-2 rounded text-sm"
            @click="showNew = false; newTaskText = ''"
          >
            Отмена
          </button>
        </div>
      </div>

      <button
        v-if="!showNew"
        type="button"
        class="mt-4 px-4 py-2 border border-dashed border-cantina-border text-cantina-muted hover:text-cantina-cream hover:border-cantina-copper rounded-lg inline-flex items-center gap-2 transition-colors"
        @click="showNew = true"
      >
        <span class="material-icons text-xl">add</span>
        Добавить задание
      </button>
    </div>
  </div>
</template>

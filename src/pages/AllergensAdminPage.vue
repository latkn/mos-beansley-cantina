<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import {
  getAllergens,
  createAllergen,
  updateAllergen,
  deleteAllergen,
  seedDefaultAllergens,
} from '@/api/allergens'

const allergens = ref([])
const loading = ref(true)
const savingId = ref(null)
const showNew = ref(false)
const newLabel = ref('')
const editDraft = ref({})
/** Выбранные id для массового удаления (только не default) */
const selectedIds = ref([])
const deletingBulk = ref(false)
/** Индекс строки для навигации стрелками */
const focusedIndex = ref(-1)

async function load() {
  loading.value = true
  try {
    allergens.value = await getAllergens()
  } finally {
    loading.value = false
  }
}

function isDefault(item) {
  return String(item.id).startsWith('default-')
}

function startEdit(item) {
  editDraft.value = { id: item.id, label: item.label }
}

function cancelEdit() {
  editDraft.value = {}
}

async function saveItem(id) {
  if (savingId.value) return
  savingId.value = id
  try {
    if (editDraft.value.id) {
      await updateAllergen(editDraft.value.id, { label: editDraft.value.label })
      cancelEdit()
    } else {
      await createAllergen({ label: newLabel.value.trim(), sort_order: allergens.value.length })
      showNew.value = false
      newLabel.value = ''
    }
    await load()
  } catch (e) {
    alert(e?.message || 'Ошибка')
  } finally {
    savingId.value = null
  }
}

function toggleSelect(id) {
  if (selectedIds.value.includes(id)) {
    selectedIds.value = selectedIds.value.filter((x) => x !== id)
  } else {
    selectedIds.value = [...selectedIds.value, id]
  }
}

function selectAllDeletable() {
  const deletable = allergens.value.filter((i) => !isDefault(i))
  selectedIds.value = deletable.map((i) => i.id)
}

function clearSelection() {
  selectedIds.value = []
}

const deletableCount = computed(() => allergens.value.filter((i) => !isDefault(i)).length)

async function removeSelected() {
  if (!selectedIds.value.length) return
  deletingBulk.value = true
  try {
    for (const id of selectedIds.value) {
      await deleteAllergen(id)
    }
    if (editDraft.value.id && selectedIds.value.includes(editDraft.value.id)) cancelEdit()
    clearSelection()
    await load()
  } catch (e) {
    alert(e?.message || 'Ошибка')
  } finally {
    deletingBulk.value = false
  }
}

async function remove(id) {
  if (!confirm('Удалить пункт из списка аллергенов?')) return
  try {
    await deleteAllergen(id)
    await load()
    if (editDraft.value.id === id) cancelEdit()
  } catch (e) {
    alert(e?.message || 'Ошибка')
  }
}

async function seedDefaults() {
  if (!confirm('Добавить базовый набор аллергенов в базу? (если список пуст)')) return
  try {
    await seedDefaultAllergens()
    await load()
  } catch (e) {
    alert(e?.message || 'Ошибка')
  }
}

function handleKeydown(e) {
  const inInput = e.target.matches('input, textarea, select')
  if (e.key === 'Escape') {
    cancelEdit()
    showNew.value = false
    newLabel.value = ''
    if (inInput) return
  }
  if (inInput) return
  e.preventDefault()
  const list = allergens.value
  if (e.key === 'ArrowUp') {
    focusedIndex.value = Math.max(-1, focusedIndex.value - 1)
    return
  }
  if (e.key === 'ArrowDown') {
    if (list.length) focusedIndex.value = Math.min(list.length - 1, focusedIndex.value + 1)
    return
  }
  if (e.key === 'Enter') {
    if (editDraft.value.id) {
      saveItem(editDraft.value.id)
      return
    }
    if (showNew.value) {
      saveItem(null)
      return
    }
    if (focusedIndex.value >= 0 && focusedIndex.value < list.length && !isDefault(list[focusedIndex.value])) {
      startEdit(list[focusedIndex.value])
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
    <div class="max-w-2xl mx-auto">
      <div class="flex items-center justify-between gap-4 mb-6">
        <h1 class="font-display text-2xl text-cantina-amber">Список аллергенов</h1>
        <router-link to="/admin/edit" class="text-cantina-sand hover:text-cantina-cream text-sm transition-colors">← Админ</router-link>
      </div>

      <p class="text-cantina-muted text-sm mb-4">
        Эти пункты показываются гостю в конце опросника: «Отметьте, на какой продукт есть аллергия». Порядок можно менять редактированием sort_order в БД или добавить новые пункты ниже.
      </p>

      <div v-if="allergens.length === 0 && !loading" class="mb-4 p-4 bg-cantina-card rounded-lg border border-cantina-amber/50">
        <p class="text-cantina-amber mb-2">Список пуст. Добавьте пункты вручную или загрузите базовый набор.</p>
        <button
          type="button"
          class="btn-cantina-primary px-4 py-2 rounded text-sm"
          @click="seedDefaults"
        >
          Заполнить базовый набор
        </button>
      </div>

      <div v-else class="mb-4">
        <button
          type="button"
          class="btn-cantina-secondary px-4 py-2 rounded text-sm"
          @click="seedDefaults"
        >
          Заполнить базовый набор (если пусто)
        </button>
      </div>

      <!-- Панель массового удаления -->
      <div
        v-if="!loading && deletableCount > 0"
        class="mb-4 flex flex-wrap items-center gap-3 py-2"
      >
        <label class="flex items-center gap-2 cursor-pointer text-cantina-muted hover:text-cantina-cream text-sm">
          <input
            type="checkbox"
            :checked="deletableCount > 0 && selectedIds.length === deletableCount"
            :indeterminate="selectedIds.length > 0 && selectedIds.length < deletableCount"
            class="rounded"
            @change="selectedIds.length === deletableCount ? clearSelection() : selectAllDeletable()"
          />
          <span>Выбрать все ({{ deletableCount }})</span>
        </label>
        <template v-if="selectedIds.length > 0">
          <button
            type="button"
            class="btn-cantina-danger px-3 py-1.5 disabled:opacity-60 rounded text-sm inline-flex items-center gap-1.5"
            :disabled="deletingBulk"
            :title="deletingBulk ? 'Удаление…' : `Удалить выбранные (${selectedIds.length})`"
            @click="removeSelected"
          >
            <span v-if="deletingBulk" class="material-icons animate-spin text-lg">hourglass_empty</span>
            <span v-else class="material-icons text-lg">delete</span>
            <span>{{ deletingBulk ? 'Удаление…' : `Удалить (${selectedIds.length})` }}</span>
          </button>
          <button
            type="button"
            class="btn-cantina-secondary px-3 py-1.5 rounded text-sm inline-flex items-center gap-1.5"
            title="Снять выбор"
            @click="clearSelection"
          >
            <span class="material-icons text-lg">clear</span>
            <span>Снять выбор</span>
          </button>
        </template>
      </div>

      <div v-if="loading" class="text-cantina-muted">Загрузка…</div>

      <ul v-else class="space-y-2">
        <li
          v-for="(item, idx) in allergens"
          :key="item.id"
          class="flex items-center gap-3 p-3 rounded-lg border border-cantina-border bg-cantina-card"
          :class="{
            'ring-2 ring-cantina-amber/60': selectedIds.includes(item.id),
            'ring-2 ring-cantina-copper/50': focusedIndex === idx && !editDraft.id,
          }"
        >
          <template v-if="!isDefault(item)">
            <label class="flex items-center flex-shrink-0 cursor-pointer" title="Выбрать для удаления">
              <input
                type="checkbox"
                :checked="selectedIds.includes(item.id)"
                class="rounded"
                @change="toggleSelect(item.id)"
              />
            </label>
          </template>
          <span v-else class="w-5 flex-shrink-0" />
          <span class="text-slate-500 w-6">{{ idx + 1 }}.</span>
          <template v-if="editDraft.id === item.id">
            <input
              v-model="editDraft.label"
              type="text"
              class="flex-1 px-3 py-1.5 bg-slate-800 border border-slate-600 rounded text-white"
              @keydown.enter="saveItem(item.id)"
              @keydown.escape="cancelEdit"
            />
            <button
              type="button"
              class="btn-cantina-primary p-1.5 rounded"
              :disabled="savingId === item.id"
              :title="savingId === item.id ? 'Сохранение…' : 'Сохранить'"
              @click="saveItem(item.id)"
            >
              <span v-if="savingId === item.id" class="material-icons animate-spin text-xl">hourglass_empty</span>
              <span v-else class="material-icons text-xl">save</span>
            </button>
            <button
              type="button"
              class="p-1.5 bg-slate-600 hover:bg-slate-500 text-white rounded"
              title="Отмена"
              @click="cancelEdit"
            >
              <span class="material-icons text-xl">close</span>
            </button>
          </template>
          <template v-else>
            <span class="flex-1 text-cantina-cream">{{ item.label }}</span>
            <template v-if="!isDefault(item)">
              <button
                type="button"
                class="p-1.5 text-cantina-copper hover:text-cantina-copper-light rounded hover:bg-cantina-surface transition-colors"
                title="Изменить"
                @click="startEdit(item)"
              >
                <span class="material-icons text-xl">edit</span>
              </button>
              <button
                type="button"
                class="p-1.5 text-red-400 hover:text-red-300 rounded hover:bg-slate-700"
                title="Удалить"
                @click="remove(item.id)"
              >
                <span class="material-icons text-xl">delete</span>
              </button>
            </template>
            <span v-else class="text-cantina-muted text-xs">(только для показа)</span>
          </template>
        </li>
      </ul>

      <div v-if="showNew" class="mt-4 p-4 rounded border border-slate-600 bg-slate-800/50 flex gap-2 flex-wrap items-center">
        <input
          v-model="newLabel"
          type="text"
          placeholder="Название аллергена"
          class="flex-1 min-w-[200px] px-3 py-2 bg-slate-800 border border-slate-600 rounded text-white"
          @keydown.enter="saveItem(null)"
          @keydown.escape="showNew = false; newLabel = ''"
        />
        <button
          type="button"
          class="btn-cantina-primary p-2 rounded"
          :disabled="!newLabel.trim() || savingId"
          :title="savingId ? 'Сохранение…' : 'Добавить'"
          @click="saveItem(null)"
        >
          <span v-if="savingId" class="material-icons animate-spin">hourglass_empty</span>
          <span v-else class="material-icons" title="Добавить">add</span>
        </button>
        <button
          type="button"
          class="p-2 bg-slate-600 hover:bg-slate-500 text-white rounded"
          title="Отмена"
          @click="showNew = false; newLabel = ''"
        >
          <span class="material-icons">close</span>
        </button>
      </div>

      <button
        v-if="!showNew"
        type="button"
        class="mt-4 px-4 py-2 border border-dashed border-cantina-border text-cantina-muted hover:text-cantina-cream hover:border-cantina-copper rounded-lg inline-flex items-center gap-2 transition-colors"
        title="Добавить аллерген"
        @click="showNew = true"
      >
        <span class="material-icons text-xl">add</span>
        <span>Добавить аллерген</span>
      </button>
    </div>
  </div>
</template>

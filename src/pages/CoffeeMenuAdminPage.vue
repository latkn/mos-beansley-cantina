<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import {
  getCoffeeMenuForAdmin,
  updateCoffeeItem,
  createCoffeeItem,
  deleteCoffeeItem,
  uploadCoffeeImage,
} from '@/api/coffee'

const items = ref([])
const loading = ref(true)
const savingId = ref(null)
const editingId = ref(null)
const draft = ref({})
const showNew = ref(false)
const selectedIds = ref([])
const deletingBulk = ref(false)
const focusedIndex = ref(-1)
const newItem = ref({
  name: '',
  experimental_level: 5,
  ingredients: '',
  prep_instructions: '',
  is_available: true,
  base_type: 'espresso',
  sweetness: 5,
  bitterness: 5,
  intensity: 5,
  extremeness: 5,
  image_url: '',
})
const uploadingImageId = ref(null) // id позиции, для которой идёт загрузка фото
const newItemImageFile = ref(null) // файл фото для новой позиции (загрузим после создания)
const newItemPreviewUrl = ref('') // превью в форме новой позиции

function ingredientsToStr(arr) {
  if (!Array.isArray(arr)) return ''
  return arr.join(', ')
}

function strToIngredients(s) {
  if (typeof s !== 'string') return []
  return s.split(',').map((x) => x.trim()).filter(Boolean)
}

async function load() {
  loading.value = true
  try {
    items.value = await getCoffeeMenuForAdmin()
  } finally {
    loading.value = false
  }
}

function startEdit(item) {
  editingId.value = item.id
  draft.value = {
    name: item.name,
    experimental_level: item.experimental_level ?? 5,
    ingredients: ingredientsToStr(item.ingredients),
    prep_instructions: item.prep_instructions ?? '',
    is_available: item.is_available !== false,
    sweetness: item.sweetness ?? 5,
    bitterness: item.bitterness ?? 5,
    intensity: item.intensity ?? 5,
    extremeness: item.extremeness ?? 5,
    image_url: item.image_url ?? '',
  }
}

function cancelEdit() {
  editingId.value = null
  draft.value = {}
}

async function save(id) {
  if (savingId.value) return
  savingId.value = id
  try {
    const payload = id ? draft.value : newItem.value
    const ingredients = strToIngredients(payload.ingredients)
    if (id) {
      await updateCoffeeItem(id, {
        name: payload.name,
        experimental_level: payload.experimental_level,
        ingredients,
        prep_instructions: payload.prep_instructions ?? '',
        is_available: payload.is_available,
        sweetness: payload.sweetness,
        bitterness: payload.bitterness,
        intensity: payload.intensity,
        extremeness: payload.extremeness,
        image_url: payload.image_url || null,
      })
      cancelEdit()
    } else {
      const created = await createCoffeeItem({
        name: payload.name,
        experimental_level: payload.experimental_level,
        ingredients,
        prep_instructions: payload.prep_instructions ?? '',
        is_available: payload.is_available,
        base_type: payload.base_type || 'espresso',
        sweetness: payload.sweetness ?? 5,
        bitterness: payload.bitterness ?? 5,
        intensity: payload.intensity ?? 5,
        extremeness: payload.extremeness ?? 5,
        image_url: null,
      })
      const fileToUpload = newItemImageFile.value
      if (fileToUpload) {
        try {
          const url = await uploadCoffeeImage(created.id, fileToUpload)
          await updateCoffeeItem(created.id, { image_url: url })
        } catch (err) {
          alert(err?.message || 'Напиток создан, но фото не загрузилось')
        }
        clearNewItemPhoto()
      }
      showNew.value = false
      newItem.value = { name: '', experimental_level: 5, ingredients: '', prep_instructions: '', is_available: true, base_type: 'espresso', sweetness: 5, bitterness: 5, intensity: 5, extremeness: 5, image_url: '' }
    }
    await load()
  } catch (e) {
    alert(e?.message || 'Ошибка сохранения')
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

function selectAll() {
  selectedIds.value = items.value.map((i) => i.id)
}

function clearSelection() {
  selectedIds.value = []
}

async function removeSelected() {
  if (!selectedIds.value.length) return
  deletingBulk.value = true
  try {
    for (const id of selectedIds.value) {
      await deleteCoffeeItem(id)
    }
    if (editingId.value && selectedIds.value.includes(editingId.value)) cancelEdit()
    clearSelection()
    await load()
  } catch (e) {
    alert(e?.message || 'Ошибка удаления')
  } finally {
    deletingBulk.value = false
  }
}

async function remove(id) {
  if (!confirm('Удалить позицию из карты?')) return
  try {
    await deleteCoffeeItem(id)
    await load()
    if (editingId.value === id) cancelEdit()
  } catch (e) {
    alert(e?.message || 'Ошибка удаления')
  }
}

async function onPhotoSelected(itemId, file) {
  if (!file?.type?.startsWith('image/')) {
    alert('Выберите файл изображения (jpg, png и т.д.)')
    return
  }
  uploadingImageId.value = itemId
  try {
    const url = await uploadCoffeeImage(itemId, file)
    const item = items.value.find((i) => i.id === itemId)
    if (editingId.value === itemId && item) setDisplayImageUrl(item, url)
    else {
      await updateCoffeeItem(itemId, { image_url: url })
      await load()
    }
  } catch (e) {
    alert(e?.message || 'Ошибка загрузки фото')
  } finally {
    uploadingImageId.value = null
  }
}

function onNewItemPhotoSelected(file) {
  if (!file?.type?.startsWith('image/')) {
    alert('Выберите файл изображения (jpg, png и т.д.)')
    return
  }
  if (newItemPreviewUrl.value) URL.revokeObjectURL(newItemPreviewUrl.value)
  newItemImageFile.value = file
  newItemPreviewUrl.value = URL.createObjectURL(file)
}

function clearNewItemPhoto() {
  if (newItemPreviewUrl.value) URL.revokeObjectURL(newItemPreviewUrl.value)
  newItemImageFile.value = null
  newItemPreviewUrl.value = ''
}

function handleNewItemPhotoChange(e) {
  const f = e.target?.files?.[0]
  if (f) onNewItemPhotoSelected(f)
  e.target.value = ''
}

function handleEditPhotoChange(itemId, e) {
  const f = e.target?.files?.[0]
  if (f) onPhotoSelected(itemId, f)
  e.target.value = ''
}

async function removeCoffeePhoto(item) {
  if (editingId.value === item.id) {
    draft.value = { ...draft.value, image_url: '' }
    return
  }
  if (displayImageUrl(item) && !confirm('Удалить фото напитка?')) return
  try {
    await updateCoffeeItem(item.id, { image_url: null })
    await load()
  } catch (e) {
    alert(e?.message || 'Не удалось удалить фото')
  }
}

function displayImageUrl(item) {
  if (editingId.value === item.id) return draft.value?.image_url ?? item.image_url
  return item.image_url
}

function setDisplayImageUrl(item, url) {
  if (editingId.value === item.id) draft.value = { ...draft.value, image_url: url || '' }
}

function toggleAvailable(item) {
  updateCoffeeItem(item.id, { is_available: !item.is_available }).then(() => load()).catch((e) => alert(e?.message))
}

function handleKeydown(e) {
  const inInput = e.target.matches('input, textarea, select')
  if (e.key === 'Escape') {
    cancelEdit()
    showNew.value = false
    if (inInput) return
  }
  if (inInput) return
  e.preventDefault()
  const list = items.value
  if (e.key === 'ArrowUp') {
    focusedIndex.value = Math.max(-1, focusedIndex.value - 1)
    return
  }
  if (e.key === 'ArrowDown') {
    if (list.length) focusedIndex.value = Math.min(list.length - 1, focusedIndex.value + 1)
    return
  }
  if (e.key === 'Enter') {
    if (editingId.value) {
      save(editingId.value)
      return
    }
    if (showNew.value) {
      save(null)
      return
    }
    if (focusedIndex.value >= 0 && focusedIndex.value < list.length) {
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
    <div class="max-w-4xl mx-auto">
      <div class="flex items-center justify-between gap-4 mb-6">
        <div>
          <h1 class="font-display text-2xl text-cantina-amber">Кофейная карта</h1>
          <p class="text-cantina-muted text-sm mt-1">
            Баллы (1–10) — уровень допуска гостя; состав — для проверки аллергий. Чекбокс — в наличии.
          </p>
        </div>
        <router-link to="/admin/edit" class="text-cantina-sand hover:text-cantina-cream text-sm transition-colors">← Админ</router-link>
      </div>

      <div v-if="loading" class="text-cantina-muted py-8">Загрузка…</div>

      <div v-else class="space-y-4">
        <!-- Новая позиция -->
        <div
          v-if="showNew"
          class="p-4 rounded-xl bg-cantina-card border border-cantina-copper/50 space-y-3"
        >
          <input
            v-model="newItem.name"
            type="text"
            placeholder="Название"
            class="w-full px-3 py-2 bg-cantina-surface border border-cantina-border rounded text-cantina-cream placeholder-cantina-muted focus:ring-2 focus:ring-cantina-copper"
          />
          <div class="flex gap-4 flex-wrap items-center">
            <label class="flex items-center gap-2">
              <span class="text-cantina-muted text-sm">Баллы</span>
              <input
                v-model.number="newItem.experimental_level"
                type="number"
                min="1"
                max="10"
                class="w-16 px-2 py-1 bg-cantina-surface border border-cantina-border rounded text-cantina-cream"
              />
            </label>
            <label class="flex items-center gap-2">
              <input v-model="newItem.is_available" type="checkbox" class="rounded accent-cantina-copper" />
              <span class="text-cantina-muted text-sm">В наличии</span>
            </label>
          </div>
          <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 text-sm">
            <label class="flex flex-col gap-0.5">
              <span class="text-cantina-muted">Сладость</span>
              <input v-model.number="newItem.sweetness" type="range" min="0" max="10" class="w-full accent-cantina-copper" />
              <span class="text-cantina-amber/90">{{ newItem.sweetness }}</span>
            </label>
            <label class="flex flex-col gap-0.5">
              <span class="text-cantina-muted">Горечь</span>
              <input v-model.number="newItem.bitterness" type="range" min="0" max="10" class="w-full accent-cantina-copper" />
              <span class="text-cantina-amber/90">{{ newItem.bitterness }}</span>
            </label>
            <label class="flex flex-col gap-0.5">
              <span class="text-cantina-muted">Интенсивность</span>
              <input v-model.number="newItem.intensity" type="range" min="0" max="10" class="w-full accent-cantina-copper" />
              <span class="text-cantina-amber/90">{{ newItem.intensity }}</span>
            </label>
            <label class="flex flex-col gap-0.5">
              <span class="text-cantina-muted">Экстрим</span>
              <input v-model.number="newItem.extremeness" type="range" min="0" max="10" class="w-full accent-cantina-copper" />
              <span class="text-cantina-amber/90">{{ newItem.extremeness }}</span>
            </label>
          </div>
          <input
            v-model="newItem.ingredients"
            type="text"
            placeholder="Состав через запятую"
            class="w-full px-3 py-2 bg-cantina-surface border border-cantina-border rounded text-cantina-cream placeholder-cantina-muted text-sm focus:ring-2 focus:ring-cantina-copper"
          />
          <textarea
            v-model="newItem.prep_instructions"
            placeholder="Инструкция для бариста (как готовить)"
            rows="3"
            class="w-full px-3 py-2 bg-cantina-surface border border-cantina-border rounded text-cantina-cream placeholder-cantina-muted text-sm resize-y focus:ring-2 focus:ring-cantina-copper"
          />
          <div class="space-y-2">
            <span class="text-cantina-muted text-sm">Фото напитка</span>
            <div class="flex flex-wrap items-center gap-3">
              <div v-if="newItemPreviewUrl" class="relative">
                <img :src="newItemPreviewUrl" alt="Превью" class="w-20 h-20 object-cover rounded-lg border border-cantina-border" />
                <button type="button" class="absolute -top-1 -right-1 w-5 h-5 rounded-full bg-cantina-danger text-cantina-cream flex items-center justify-center text-xs" title="Убрать фото" @click="clearNewItemPhoto">×</button>
              </div>
              <label class="cursor-pointer px-3 py-2 rounded-lg border border-cantina-border text-cantina-sand hover:border-cantina-copper text-sm inline-flex items-center gap-1">
                <span class="material-icons text-lg">add_photo_alternate</span>
                <span>{{ newItemPreviewUrl ? 'Заменить' : 'Загрузить фото' }}</span>
                <input type="file" accept="image/*" class="hidden" @change="handleNewItemPhotoChange" />
              </label>
            </div>
          </div>
          <div class="flex gap-2">
            <button
              type="button"
              class="btn-cantina-primary p-2 rounded"
              :disabled="!newItem.name.trim() || savingId"
              :title="savingId ? 'Сохранение…' : 'Добавить'"
              @click="save(null)"
            >
              <span v-if="savingId" class="material-icons animate-spin">hourglass_empty</span>
              <span v-else class="material-icons">add</span>
            </button>
            <button
              type="button"
              class="btn-cantina-secondary p-2 rounded"
              title="Отмена"
              @click="showNew = false; clearNewItemPhoto(); newItem = { name: '', experimental_level: 5, ingredients: '', prep_instructions: '', is_available: true, base_type: 'espresso', sweetness: 5, bitterness: 5, intensity: 5, extremeness: 5, image_url: '' }"
            >
              <span class="material-icons">close</span>
            </button>
          </div>
        </div>

        <button
          v-if="!showNew"
          type="button"
          class="w-full py-2 border border-dashed border-cantina-border rounded-lg text-cantina-muted hover:border-cantina-copper hover:text-cantina-copper text-sm inline-flex items-center justify-center gap-2 transition-colors"
          title="Добавить позицию"
          @click="showNew = true"
        >
          <span class="material-icons text-xl">add</span>
          <span>Добавить позицию</span>
        </button>

        <!-- Панель массового удаления -->
        <div
          v-if="items.length > 0"
          class="flex flex-wrap items-center gap-3 py-2"
        >
          <label class="flex items-center gap-2 cursor-pointer text-slate-400 hover:text-white text-sm">
            <input
              type="checkbox"
              :checked="items.length > 0 && selectedIds.length === items.length"
              :indeterminate="selectedIds.length > 0 && selectedIds.length < items.length"
              class="rounded"
              @change="selectedIds.length === items.length ? clearSelection() : selectAll()"
            />
            <span>Выбрать все ({{ items.length }})</span>
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

        <!-- Список позиций -->
        <div
          v-for="(item, idx) in items"
          :key="item.id"
          class="rounded-xl border overflow-hidden"
          :class="[
            item.is_available !== false ? 'bg-cantina-card border-cantina-border' : 'bg-cantina-card/60 border-cantina-border opacity-80',
            selectedIds.includes(item.id) ? 'ring-2 ring-cantina-amber/60' : '',
            focusedIndex === idx && !editingId ? 'ring-2 ring-cantina-copper/50' : '',
          ]"
        >
          <div class="p-4 flex flex-wrap items-start gap-4">
            <label class="flex items-center flex-shrink-0 cursor-pointer" title="Выбрать для удаления">
              <input
                type="checkbox"
                :checked="selectedIds.includes(item.id)"
                class="rounded w-5 h-5"
                @change="toggleSelect(item.id)"
              />
            </label>
            <!-- Фото напитка: загрузка / замена / удаление без входа в редактирование (фикс. размер — верстка не едет) -->
            <div class="flex flex-col items-center gap-1 flex-shrink-0 w-20">
              <div class="relative w-20 h-20 rounded-xl border border-cantina-border bg-cantina-surface overflow-hidden group flex-shrink-0">
                <template v-if="displayImageUrl(item)">
                  <img
                    :src="displayImageUrl(item)"
                    :alt="item.name"
                    class="w-full h-full object-cover"
                  />
                  <div class="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-1 sm:flex">
                    <label
                      class="p-1.5 rounded-full bg-cantina-cream/95 text-cantina-ink cursor-pointer hover:bg-cantina-cream shadow"
                      :title="uploadingImageId === item.id ? 'Загрузка…' : 'Заменить фото'"
                    >
                      <span v-if="uploadingImageId === item.id" class="material-icons text-lg animate-spin">hourglass_empty</span>
                      <span v-else class="material-icons text-lg">photo_camera</span>
                      <input
                        type="file"
                        accept="image/*"
                        class="hidden"
                        :disabled="uploadingImageId === item.id"
                        @change="(e) => handleEditPhotoChange(item.id, e)"
                      />
                    </label>
                    <button
                      type="button"
                      class="p-1.5 rounded-full bg-cantina-danger/95 text-cantina-cream hover:bg-cantina-danger shadow"
                      title="Удалить фото"
                      @click.stop="removeCoffeePhoto(item)"
                    >
                      <span class="material-icons text-lg">delete</span>
                    </button>
                  </div>
                </template>
                <label
                  v-else
                  class="absolute inset-0 flex flex-col items-center justify-center gap-0.5 cursor-pointer border-2 border-dashed border-cantina-border hover:border-cantina-copper hover:bg-cantina-copper/10 rounded-xl transition-colors"
                  :class="{ 'pointer-events-none': uploadingImageId === item.id }"
                >
                  <span v-if="uploadingImageId === item.id" class="material-icons text-2xl text-cantina-copper animate-spin">hourglass_empty</span>
                  <template v-else>
                    <span class="material-icons text-2xl text-cantina-muted">add_photo_alternate</span>
                    <span class="text-[10px] text-cantina-muted font-mono">Фото</span>
                  </template>
                  <input
                    type="file"
                    accept="image/*"
                    class="hidden"
                    :disabled="uploadingImageId === item.id"
                    @change="(e) => handleEditPhotoChange(item.id, e)"
                  />
                </label>
              </div>
              <!-- Кнопки под превью: место зарезервировано, чтобы верстка не прыгала при появлении фото -->
              <div class="h-5 w-full flex items-center justify-center min-h-5">
                <template v-if="displayImageUrl(item)">
                  <div class="flex gap-2 text-cantina-muted">
                    <label class="hover:text-cantina-copper text-[10px] font-mono cursor-pointer flex items-center gap-0.5" :class="{ 'pointer-events-none': uploadingImageId === item.id }">
                      <span v-if="uploadingImageId === item.id" class="material-icons text-xs animate-spin">hourglass_empty</span>
                      <span v-else class="material-icons text-xs">photo_camera</span>
                      <span>Заменить</span>
                      <input type="file" accept="image/*" class="hidden" :disabled="uploadingImageId === item.id" @change="(e) => handleEditPhotoChange(item.id, e)" />
                    </label>
                    <button type="button" class="text-cantina-muted hover:text-cantina-danger text-[10px] font-mono flex items-center gap-0.5" @click.stop="removeCoffeePhoto(item)">
                      <span class="material-icons text-xs">delete</span>
                      <span>Удалить</span>
                    </button>
                  </div>
                </template>
                <span v-else class="invisible text-[10px] select-none">.</span>
              </div>
            </div>
            <!-- Чекбокс доступности -->
            <label class="flex items-center gap-2 flex-shrink-0 cursor-pointer" title="В наличии / закончилось">
              <input
                type="checkbox"
                :checked="item.is_available !== false"
                class="w-5 h-5 rounded"
                @change="toggleAvailable(item)"
              />
              <span class="text-cantina-muted text-xs hidden sm:inline">В наличии</span>
            </label>

            <div class="min-w-0 flex-1 space-y-2">
              <template v-if="editingId === item.id">
                <input
                  v-model="draft.name"
                  type="text"
                  class="w-full px-3 py-2 bg-slate-700 border border-slate-600 rounded text-white font-mono"
                  @keydown.enter="save(item.id)"
                  @keydown.escape="cancelEdit"
                />
                <div class="flex gap-3 items-center flex-wrap">
                  <label class="flex items-center gap-1">
                    <span class="text-cantina-muted text-xs">Баллы</span>
                    <input
                      v-model.number="draft.experimental_level"
                      type="number"
                      min="1"
                      max="10"
                      class="w-14 px-2 py-1 bg-cantina-surface border border-cantina-border rounded text-cantina-cream text-sm"
                    />
                  </label>
                  <label class="flex items-center gap-1">
                    <input v-model="draft.is_available" type="checkbox" class="rounded" />
                    <span class="text-cantina-muted text-xs">В наличии</span>
                  </label>
                </div>
                <div class="grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs">
                  <label class="flex flex-col gap-0.5">
                    <span class="text-cantina-muted">Сладость</span>
                    <input v-model.number="draft.sweetness" type="range" min="0" max="10" class="w-full accent-cantina-copper" />
                    <span class="text-cantina-amber/90">{{ draft.sweetness }}</span>
                  </label>
                  <label class="flex flex-col gap-0.5">
                    <span class="text-cantina-muted">Горечь</span>
                    <input v-model.number="draft.bitterness" type="range" min="0" max="10" class="w-full accent-cantina-copper" />
                    <span class="text-cantina-amber/90">{{ draft.bitterness }}</span>
                  </label>
                  <label class="flex flex-col gap-0.5">
                    <span class="text-cantina-muted">Интенсивность</span>
                    <input v-model.number="draft.intensity" type="range" min="0" max="10" class="w-full accent-cantina-copper" />
                    <span class="text-cantina-amber/90">{{ draft.intensity }}</span>
                  </label>
                  <label class="flex flex-col gap-0.5">
                    <span class="text-cantina-muted">Экстрим</span>
                    <input v-model.number="draft.extremeness" type="range" min="0" max="10" class="w-full accent-cantina-copper" />
                    <span class="text-cantina-amber/90">{{ draft.extremeness }}</span>
                  </label>
                </div>
                <input
                  v-model="draft.ingredients"
                  type="text"
                  placeholder="Состав через запятую"
                  class="w-full px-3 py-2 bg-cantina-surface border border-cantina-border rounded text-cantina-cream text-sm placeholder-cantina-muted focus:ring-2 focus:ring-cantina-copper"
                />
                <textarea
                  v-model="draft.prep_instructions"
                  placeholder="Инструкция для бариста (как готовить)"
                  rows="3"
                  class="w-full px-3 py-2 bg-cantina-surface border border-cantina-border rounded text-cantina-cream text-sm placeholder-cantina-muted resize-y focus:ring-2 focus:ring-cantina-copper"
                />
                <div class="flex gap-2">
                  <button
                    type="button"
                    class="btn-cantina-primary p-1.5 rounded"
                    :disabled="!!savingId"
                    :title="savingId === item.id ? 'Сохранение…' : 'Сохранить'"
                    @click="save(item.id)"
                  >
                    <span v-if="savingId === item.id" class="material-icons animate-spin text-xl">hourglass_empty</span>
                    <span v-else class="material-icons text-xl">save</span>
                  </button>
                  <button
                    type="button"
                    class="btn-cantina-secondary p-1.5 rounded"
                    title="Отмена"
                    @click="cancelEdit"
                  >
                    <span class="material-icons text-xl">close</span>
                  </button>
                </div>
              </template>
              <template v-else>
                <div class="flex items-center gap-2 flex-wrap">
                  <span class="font-bold text-cantina-cream">{{ item.name }}</span>
                  <span class="text-cantina-amber/90 text-sm">· {{ item.experimental_level ?? 1 }} баллов</span>
                  <span class="text-cantina-muted text-xs">
                    С{{ item.sweetness ?? 5 }} Г{{ item.bitterness ?? 5 }} И{{ item.intensity ?? 5 }} Э{{ item.extremeness ?? 5 }}
                  </span>
                </div>
                <p v-if="(item.ingredients || []).length" class="text-cantina-muted text-sm">
                  Состав: {{ ingredientsToStr(item.ingredients) }}
                </p>
                <p v-if="item.prep_instructions" class="text-cantina-copper/90 text-sm whitespace-pre-wrap">{{ item.prep_instructions }}</p>
                <div class="flex gap-1 mt-1">
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
                    class="p-1.5 text-cantina-danger hover:opacity-90 rounded hover:bg-cantina-surface transition-colors"
                    title="Удалить"
                    @click="remove(item.id)"
                  >
                    <span class="material-icons text-xl">delete</span>
                  </button>
                </div>
              </template>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

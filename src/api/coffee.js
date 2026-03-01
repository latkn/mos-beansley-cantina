import { supabase, isSupabaseAvailable } from '@/lib/supabase'
import { calculateProfileFromAnswers, findBestDrinks, findBestDrinksWithScores } from '@/lib/quizProfile'

const COFFEE_IMAGES_BUCKET = 'coffee-images'

/** Загрузить фото напитка в Storage и вернуть public URL. Bucket "coffee-images" должен быть создан и public. */
export async function uploadCoffeeImage(coffeeId, file) {
  if (!isSupabaseAvailable() || !supabase) throw new Error('Нет связи с сервером')
  const ext = file.name?.match(/\.[a-z0-9]+$/i)?.[0] || '.jpg'
  const path = `${coffeeId}/${Date.now()}${ext}`
  const { data, error } = await supabase.storage.from(COFFEE_IMAGES_BUCKET).upload(path, file, {
    cacheControl: '3600',
    upsert: false,
  })
  if (error) throw error
  const { data: urlData } = supabase.storage.from(COFFEE_IMAGES_BUCKET).getPublicUrl(data.path)
  return urlData.publicUrl
}

let coffeeMenuCache = null

export function invalidateCoffeeCache() {
  coffeeMenuCache = null
}

export async function getCoffeeMenu() {
  if (coffeeMenuCache) return coffeeMenuCache
  if (isSupabaseAvailable()) {
    const { data, error } = await supabase
      .from('coffee_menu')
      .select('*')
      .eq('is_available', true)
      .order('experimental_level', { ascending: true })
    if (error) throw error
    coffeeMenuCache = normalizeDrinkParams(data ?? [])
    return coffeeMenuCache
  }
  return getDefaultCoffeeMenu()

  function normalizeDrinkParams(rows) {
    return rows.map((r) => ({
      ...r,
      sweetness: r.sweetness ?? 5,
      bitterness: r.bitterness ?? 5,
      intensity: r.intensity ?? 5,
      extremeness: r.extremeness ?? 5,
    }))
  }
}

/** Для админки: все позиции, включая недоступные */
export async function getCoffeeMenuForAdmin() {
  if (!isSupabaseAvailable()) return getDefaultCoffeeMenu()
  const { data, error } = await supabase
    .from('coffee_menu')
    .select('*')
    .order('experimental_level', { ascending: true })
    .order('name', { ascending: true })
  if (error) throw error
  return data ?? []
}

/** Совпадение по подстроке или по корню слова (финики / финиковый / финиках) */
const ALLERGY_ROOT_LEN = 4
function ingredientMatchesAllergy(ingredient, allergy) {
  const i = String(ingredient ?? '').trim().toLowerCase()
  const a = String(allergy ?? '').trim().toLowerCase()
  if (!a) return false
  if (i.includes(a) || a.includes(i)) return true
  const iWords = i.split(/\s+/).filter(Boolean)
  const aWords = a.split(/\s+/).filter(Boolean)
  for (const aw of aWords) {
    if (aw.length < 3) continue
    const root = aw.length >= ALLERGY_ROOT_LEN ? aw.slice(0, ALLERGY_ROOT_LEN) : aw
    for (const iw of iWords) {
      if (iw.length < 3) continue
      if (iw.includes(aw) || aw.includes(iw)) return true
      if (iw.includes(root) || iw.slice(0, ALLERGY_ROOT_LEN) === root) return true
    }
  }
  return false
}

/** Есть ли в кофе хотя бы один ингредиент из списка аллергий */
function coffeeHasAllergen(coffee, allergies) {
  const list = Array.isArray(allergies) ? allergies : []
  if (!list.length) return false
  const ingredients = Array.isArray(coffee.ingredients) ? coffee.ingredients : []
  for (const allergy of list) {
    for (const ing of ingredients) {
      if (ingredientMatchesAllergy(ing, allergy)) return true
    }
  }
  return false
}

export function getCoffeeByClearance(clearanceLevel, allergies = []) {
  return getCoffeeMenu().then((menu) => {
    let list = menu.filter((c) => (c.experimental_level ?? 1) <= clearanceLevel)
    if (allergies?.length) {
      list = list.filter((c) => !coffeeHasAllergen(c, allergies))
    }
    return list
  })
}

export function getRecommendedCoffees(clearanceLevel, count = 3, allergies = []) {
  return getCoffeeByClearance(clearanceLevel, allergies).then((available) => {
    const shuffled = [...available].sort(() => Math.random() - 0.5)
    return shuffled.slice(0, Math.min(count, shuffled.length))
  })
}

/**
 * Рекомендация по профилю из опроса (4 параметра). Евклидова дистанция + фильтр по аллергиям.
 * @param {Array|Object} quizAnswersOrProfile - массив { answer, question } или объект { sweetness, bitterness, intensity, extremeness } (0–10)
 * @param {Array} allergies - список аллергий
 * @param {number} count - сколько напитков вернуть
 */
export async function getRecommendedCoffeesByProfile(quizAnswersOrProfile, allergies = [], count = 3) {
  const menu = await getCoffeeMenu()
  const profile = Array.isArray(quizAnswersOrProfile)
    ? calculateProfileFromAnswers(quizAnswersOrProfile).normalized
    : {
        sweetness: quizAnswersOrProfile.sweetness ?? 5,
        bitterness: quizAnswersOrProfile.bitterness ?? 5,
        intensity: quizAnswersOrProfile.intensity ?? 5,
        extremeness: quizAnswersOrProfile.extremeness ?? 5,
      }
  return findBestDrinks(profile, menu, allergies, count)
}

/**
 * Топ count напитков с процентом совпадения профилю гостя (для карточки баристы).
 * Профиль гостя — по квизу (4 параметра); при отсутствии — нейтральный 5,5,5,5.
 */
export async function getRecommendedCoffeesWithScores(guest, allergies = [], count = 3) {
  const menu = await getCoffeeMenu()
  const allergiesList = Array.isArray(allergies) ? allergies : []
  const profile = {
    sweetness: Number(guest?.sweetness ?? 5),
    bitterness: Number(guest?.bitterness ?? 5),
    intensity: Number(guest?.intensity ?? 5),
    extremeness: Number(guest?.extremeness ?? 5),
  }
  return findBestDrinksWithScores(profile, menu, allergiesList, count)
}

function clamp0_10(v) {
  return Math.min(10, Math.max(0, Number(v) ?? 5))
}

export async function updateCoffeeItem(id, data) {
  if (!isSupabaseAvailable()) throw new Error('Нет связи с сервером')
  const payload = {}
  if (data.name !== undefined) payload.name = data.name
  if (data.experimental_level !== undefined) payload.experimental_level = Math.min(10, Math.max(1, data.experimental_level))
  if (data.ingredients !== undefined) payload.ingredients = Array.isArray(data.ingredients) ? data.ingredients : (typeof data.ingredients === 'string' ? data.ingredients.split(',').map((s) => s.trim()).filter(Boolean) : [])
  if (data.is_available !== undefined) payload.is_available = !!data.is_available
  if (data.base_type !== undefined) payload.base_type = data.base_type
  if (data.description !== undefined) payload.description = data.description
  if (data.prep_instructions !== undefined) payload.prep_instructions = data.prep_instructions
  if (data.sweetness !== undefined) payload.sweetness = clamp0_10(data.sweetness)
  if (data.bitterness !== undefined) payload.bitterness = clamp0_10(data.bitterness)
  if (data.intensity !== undefined) payload.intensity = clamp0_10(data.intensity)
  if (data.extremeness !== undefined) payload.extremeness = clamp0_10(data.extremeness)
  if (data.image_url !== undefined) payload.image_url = data.image_url || null
  const { data: row, error } = await supabase.from('coffee_menu').update(payload).eq('id', id).select().single()
  if (error) throw error
  invalidateCoffeeCache()
  return row
}

export async function createCoffeeItem(data) {
  if (!isSupabaseAvailable()) throw new Error('Нет связи с сервером')
  const ingredients = Array.isArray(data.ingredients) ? data.ingredients : (typeof data.ingredients === 'string' ? data.ingredients.split(',').map((s) => s.trim()).filter(Boolean) : [])
  const { data: row, error } = await supabase
    .from('coffee_menu')
    .insert({
      name: data.name || 'Новый напиток',
      base_type: data.base_type || 'espresso',
      experimental_level: Math.min(10, Math.max(1, data.experimental_level ?? 5)),
      ingredients,
      is_available: data.is_available !== false,
      description: data.description || null,
      prep_instructions: data.prep_instructions ?? null,
      sweetness: clamp0_10(data.sweetness),
      bitterness: clamp0_10(data.bitterness),
      intensity: clamp0_10(data.intensity),
      extremeness: clamp0_10(data.extremeness),
      image_url: data.image_url || null,
    })
    .select()
    .single()
  if (error) throw error
  invalidateCoffeeCache()
  return row
}

export async function deleteCoffeeItem(id) {
  if (!isSupabaseAvailable()) throw new Error('Нет связи с сервером')
  const { error } = await supabase.from('coffee_menu').delete().eq('id', id)
  if (error) throw error
  invalidateCoffeeCache()
}

function getDefaultCoffeeMenu() {
  const def = (s, b, i, e) => ({ sweetness: s, bitterness: b, intensity: i, extremeness: e })
  return Promise.resolve([
    { id: '1', name: 'Эспрессо', base_type: 'espresso', experimental_level: 1, ingredients: [], is_available: true, ...def(2, 7, 8, 2) },
    { id: '2', name: 'Американо', base_type: 'espresso', experimental_level: 1, ingredients: [], is_available: true, ...def(1, 6, 6, 1) },
    { id: '3', name: 'Капучино', base_type: 'espresso', experimental_level: 2, ingredients: ['молоко', 'кофе'], is_available: true, ...def(4, 4, 5, 2) },
    { id: '4', name: 'Латте', base_type: 'espresso', experimental_level: 2, ingredients: ['молоко', 'кофе'], is_available: true, ...def(5, 3, 4, 2) },
    { id: '5', name: 'Фильтр', base_type: 'filter', experimental_level: 2, ingredients: ['кофе'], is_available: true, ...def(2, 5, 5, 3) },
    { id: '6', name: 'Колд брю', base_type: 'cold_brew', experimental_level: 4, ingredients: ['кофе'], is_available: true, ...def(2, 5, 6, 5) },
  ])
}

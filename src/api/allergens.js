import { supabase, isSupabaseAvailable } from '@/lib/supabase'

/** Базовый набор, если в БД пусто или Supabase недоступен */
export const DEFAULT_ALLERGENS = [
  'Молочные продукты',
  'Мёд',
  'Имбирь',
  'Чили / острый перец',
  'Цитрусовые',
  'Какао',
  'Специи',
  'Финики',
  'Травы (мята, базилик)',
  'Самбал / орехи / морепродукты',
]

/**
 * Список аллергенов для опросника и админки (по sort_order).
 * @returns {Promise<Array<{ id: string, label: string, sort_order: number }>>}
 */
export async function getAllergens() {
  if (!isSupabaseAvailable()) {
    return DEFAULT_ALLERGENS.map((label, i) => ({ id: `default-${i}`, label, sort_order: i }))
  }
  const { data, error } = await supabase
    .from('allergens')
    .select('id, label, sort_order')
    .order('sort_order', { ascending: true })
  if (error) throw error
  const list = data ?? []
  if (list.length === 0) {
    return DEFAULT_ALLERGENS.map((label, i) => ({ id: `default-${i}`, label, sort_order: i }))
  }
  return list
}

export async function createAllergen(payload) {
  if (!isSupabaseAvailable()) throw new Error('Нет связи с сервером')
  const { data, error } = await supabase
    .from('allergens')
    .insert({
      label: payload.label?.trim() || 'Аллерген',
      sort_order: Number(payload.sort_order ?? 0),
    })
    .select()
    .single()
  if (error) throw error
  return data
}

export async function updateAllergen(id, payload) {
  if (!isSupabaseAvailable()) throw new Error('Нет связи с сервером')
  const body = {}
  if (payload.label !== undefined) body.label = payload.label.trim()
  if (payload.sort_order !== undefined) body.sort_order = Number(payload.sort_order)
  const { data, error } = await supabase.from('allergens').update(body).eq('id', id).select().single()
  if (error) throw error
  return data
}

export async function deleteAllergen(id) {
  if (!isSupabaseAvailable()) throw new Error('Нет связи с сервером')
  const { error } = await supabase.from('allergens').delete().eq('id', id)
  if (error) throw error
}

/** Вставить базовый набор, если таблица пуста (для админки). */
export async function seedDefaultAllergens() {
  if (!isSupabaseAvailable()) throw new Error('Нет связи с сервером')
  const { data: existing } = await supabase.from('allergens').select('id').limit(1)
  if (existing?.length > 0) return
  await supabase.from('allergens').insert(
    DEFAULT_ALLERGENS.map((label, i) => ({ label, sort_order: i }))
  )
}

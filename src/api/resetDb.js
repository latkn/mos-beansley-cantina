import { supabase, isSupabaseAvailable } from '@/lib/supabase'

/**
 * Порядок удаления: сначала таблицы, зависящие от других (FK), затем независимые.
 * Полный сброс всех данных приложения.
 */
const TABLES_IN_ORDER = [
  'visits',
  'planet_members',
  'planet_tasks',
  'coffee_orders',
  'planets',
  'quiz_answers',
  'guests',
  'tamada_tasks',
  'quiz_questions',
  'coffee_menu',
  'allergens',
  'races',
]

const STORAGE_BUCKETS = ['coffee-images', 'planet-photos']

async function clearStorageBucket(bucketName) {
  const { data: files } = await supabase.storage.from(bucketName).list('', { limit: 1000 })
  if (!files?.length) return
  const paths = files.filter((f) => f.name).map((f) => f.name)
  if (paths.length) await supabase.storage.from(bucketName).remove(paths)
}

/**
 * Полностью обнуляет базу: удаляет все строки из всех таблиц и файлы в storage.
 * Требует подтверждения на клиенте перед вызовом.
 */
export async function resetDatabase() {
  if (!isSupabaseAvailable() || !supabase) {
    throw new Error('Нет связи с сервером')
  }

  const errors = []

  for (const table of TABLES_IN_ORDER) {
    const { error } = await supabase.from(table).delete().neq('id', '00000000-0000-0000-0000-000000000000')
    if (error) errors.push({ table, message: error.message })
  }

  for (const bucket of STORAGE_BUCKETS) {
    try {
      await clearStorageBucket(bucket)
    } catch (e) {
      errors.push({ bucket, message: e?.message || 'Ошибка очистки' })
    }
  }

  if (errors.length) {
    throw new Error(errors.map((e) => `${e.table || e.bucket}: ${e.message}`).join('; '))
  }
}

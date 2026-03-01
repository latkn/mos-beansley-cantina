import { supabase, isSupabaseAvailable } from '@/lib/supabase'

/** Список заданий для тамады (активные, по sort_order). */
export async function getTamadaTasks(activeOnly = true) {
  if (!isSupabaseAvailable()) return []
  let q = supabase
    .from('tamada_tasks')
    .select('id, task_text, race_id, sort_order, is_active, difficulty')
    .order('sort_order', { ascending: true })
  if (activeOnly) q = q.eq('is_active', true)
  const { data, error } = await q
  if (error) throw error
  return data ?? []
}

/** Все задания (для редактора — включая неактивные). */
export async function getAllTamadaTasks() {
  return getTamadaTasks(false)
}

export async function createTamadaTask(payload) {
  if (!isSupabaseAvailable()) throw new Error('Нет связи с сервером')
  const { data, error } = await supabase
    .from('tamada_tasks')
    .insert({
      task_text: payload.task_text?.trim() || 'Задание',
      race_id: payload.race_id ?? null,
      sort_order: Number(payload.sort_order ?? 0),
      is_active: payload.is_active !== false,
      difficulty: payload.difficulty != null ? Math.min(5, Math.max(1, Number(payload.difficulty))) : 3,
    })
    .select()
    .single()
  if (error) throw error
  return data
}

export async function updateTamadaTask(id, payload) {
  if (!isSupabaseAvailable()) throw new Error('Нет связи с сервером')
  const body = {}
  if (payload.task_text !== undefined) body.task_text = payload.task_text.trim()
  if (payload.race_id !== undefined) body.race_id = payload.race_id
  if (payload.sort_order !== undefined) body.sort_order = Number(payload.sort_order)
  if (payload.is_active !== undefined) body.is_active = !!payload.is_active
  if (payload.difficulty !== undefined) body.difficulty = Math.min(5, Math.max(1, Number(payload.difficulty)))
  const { data, error } = await supabase
    .from('tamada_tasks')
    .update(body)
    .eq('id', id)
    .select()
    .single()
  if (error) throw error
  return data
}

export async function deleteTamadaTask(id) {
  if (!isSupabaseAvailable()) throw new Error('Нет связи с сервером')
  const { error } = await supabase.from('tamada_tasks').delete().eq('id', id)
  if (error) throw error
}

/** Случайное задание из активных (для кнопки «Объединить расу»). */
export async function getRandomTamadaTask() {
  const tasks = await getTamadaTasks(true)
  if (tasks.length === 0) return null
  return tasks[Math.floor(Math.random() * tasks.length)]
}

/**
 * Случайное задание по сложности (1–5). Чем выше готовность гостей к экстриму/остроте — тем сложнее задание.
 * Берёт задания с указанной сложностью; если таких нет — ближайшая сложность.
 */
export async function getRandomTamadaTaskByDifficulty(targetDifficulty) {
  const tasks = await getTamadaTasks(true)
  if (tasks.length === 0) return null
  const d = Math.min(5, Math.max(1, Number(targetDifficulty) || 3))
  const exact = tasks.filter((t) => (t.difficulty ?? 3) === d)
  const pool = exact.length > 0 ? exact : tasks
  const byDistance = pool.slice().sort((a, b) => {
    const da = Math.abs((a.difficulty ?? 3) - d)
    const db = Math.abs((b.difficulty ?? 3) - d)
    return da - db
  })
  const closest = byDistance.filter((t) => Math.abs((t.difficulty ?? 3) - d) === Math.abs((byDistance[0].difficulty ?? 3) - d))
  return closest[Math.floor(Math.random() * closest.length)]
}

/** Уровень экстрима 1–3: 1 лёгкий, 2 медиум, 3 экстремально. По difficulty 1–5: 1–2→1, 3→2, 4–5→3. */
export function difficultyToExtremenessLevel(difficulty) {
  const d = Number(difficulty)
  if (Number.isNaN(d) || d <= 2) return 1
  if (d <= 3) return 2
  return 3
}

/**
 * Случайное задание по уровню экстрима (1–3). Уровень задания сохраняется при смене задания.
 * 1 — лёгкий (difficulty 1–2), 2 — медиум (3), 3 — экстремально (4–5).
 */
export async function getRandomTamadaTaskByLevel(level) {
  const tasks = await getTamadaTasks(true)
  if (tasks.length === 0) return null
  const L = Math.min(3, Math.max(1, Number(level) || 2))
  const difficultyRange = L === 1 ? [1, 2] : L === 2 ? [3] : [4, 5]
  const pool = tasks.filter((t) => difficultyRange.includes(t.difficulty ?? 3))
  const use = pool.length > 0 ? pool : tasks
  return use[Math.floor(Math.random() * use.length)]
}

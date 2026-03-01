import { supabase, isSupabaseAvailable } from '@/lib/supabase'

/**
 * Все активные вопросы с ответами (для админки и для выбора случайных).
 */
export async function getQuestionsWithAnswers(activeOnly = false) {
  if (!isSupabaseAvailable()) return []
  let q = supabase
    .from('quiz_questions')
    .select(
      `
      id,
      text,
      is_active,
      weight,
      sort_order,
      is_galaxy_watcher,
      created_at,
      quiz_answers (
        id,
        text,
        sweetness_delta,
        bitterness_delta,
        intensity_delta,
        extremeness_delta,
        sort_order
      )
    `
    )
    .order('sort_order', { ascending: true })
  if (activeOnly) q = q.eq('is_active', true)
  const { data, error } = await q
  if (error) throw error
  const list = data ?? []
  list.forEach((row) => {
    if (Array.isArray(row.quiz_answers)) {
      row.quiz_answers.sort((a, b) => (a.sort_order ?? 0) - (b.sort_order ?? 0))
    }
  })
  return list
}

/**
 * Случайные активные вопросы для сессии опроса.
 * В каждом сете ровно один вопрос из рубрики «Смотрящий по галактике спрашивает», остальные — случайные.
 * @param {number} count - количество вопросов (по умолчанию 5)
 */
export async function getRandomQuestions(count = 5) {
  const all = await getQuestionsWithAnswers(true)
  if (all.length === 0) return []
  const galaxyWatcher = all.filter((q) => q.is_galaxy_watcher === true)
  const rest = all.filter((q) => q.is_galaxy_watcher !== true)
  const result = []
  if (galaxyWatcher.length > 0) {
    const one = galaxyWatcher[Math.floor(Math.random() * galaxyWatcher.length)]
    result.push(one)
  }
  const needMore = count - result.length
  const shuffledRest = [...rest].sort(() => Math.random() - 0.5)
  for (let i = 0; i < needMore && i < shuffledRest.length; i++) {
    result.push(shuffledRest[i])
  }
  return result.sort(() => Math.random() - 0.5)
}

/**
 * Один вопрос по id с ответами.
 */
export async function getQuestionById(id) {
  if (!isSupabaseAvailable()) return null
  const { data, error } = await supabase
    .from('quiz_questions')
    .select(
      `
      *,
      quiz_answers (*)
    `
    )
    .eq('id', id)
    .single()
  if (error) return null
  return data
}

// ——— CRUD вопросов ———

export async function createQuestion(payload) {
  if (!isSupabaseAvailable()) throw new Error('Нет связи с сервером')
  const { data, error } = await supabase
    .from('quiz_questions')
    .insert({
      text: payload.text || 'Вопрос',
      is_active: payload.is_active !== false,
      weight: Math.max(0, Number(payload.weight ?? 1)),
      sort_order: Number(payload.sort_order ?? 0) || 0,
      is_galaxy_watcher: payload.is_galaxy_watcher === true,
    })
    .select()
    .single()
  if (error) throw error
  return data
}

export async function updateQuestion(id, payload) {
  if (!isSupabaseAvailable()) throw new Error('Нет связи с сервером')
  const body = {}
  if (payload.text !== undefined) body.text = payload.text
  if (payload.is_active !== undefined) body.is_active = !!payload.is_active
  if (payload.weight !== undefined) body.weight = Math.max(0, Number(payload.weight))
  if (payload.sort_order !== undefined) body.sort_order = Number(payload.sort_order)
  if (payload.is_galaxy_watcher !== undefined) body.is_galaxy_watcher = !!payload.is_galaxy_watcher
  const { data, error } = await supabase.from('quiz_questions').update(body).eq('id', id).select().single()
  if (error) throw error
  return data
}

export async function deleteQuestion(id) {
  if (!isSupabaseAvailable()) throw new Error('Нет связи с сервером')
  const { error } = await supabase.from('quiz_questions').delete().eq('id', id)
  if (error) throw error
}

// ——— CRUD ответов ———

function clampDelta(v, min, max) {
  return Math.min(max, Math.max(min, Number(v) || 0))
}

export async function createAnswer(questionId, payload) {
  if (!isSupabaseAvailable()) throw new Error('Нет связи с сервером')
  const { data, error } = await supabase
    .from('quiz_answers')
    .insert({
      question_id: questionId,
      text: payload.text || 'Ответ',
      sweetness_delta: clampDelta(payload.sweetness_delta, -3, 3),
      bitterness_delta: clampDelta(payload.bitterness_delta, -3, 3),
      intensity_delta: clampDelta(payload.intensity_delta, -3, 3),
      extremeness_delta: clampDelta(payload.extremeness_delta, -3, 5),
      sort_order: Number(payload.sort_order ?? 0) || 0,
    })
    .select()
    .single()
  if (error) throw error
  return data
}

export async function updateAnswer(id, payload) {
  if (!isSupabaseAvailable()) throw new Error('Нет связи с сервером')
  const body = {}
  if (payload.text !== undefined) body.text = payload.text
  if (payload.sweetness_delta !== undefined) body.sweetness_delta = clampDelta(payload.sweetness_delta, -3, 3)
  if (payload.bitterness_delta !== undefined) body.bitterness_delta = clampDelta(payload.bitterness_delta, -3, 3)
  if (payload.intensity_delta !== undefined) body.intensity_delta = clampDelta(payload.intensity_delta, -3, 3)
  if (payload.extremeness_delta !== undefined) body.extremeness_delta = clampDelta(payload.extremeness_delta, -3, 5)
  if (payload.sort_order !== undefined) body.sort_order = Number(payload.sort_order)
  const { data, error } = await supabase.from('quiz_answers').update(body).eq('id', id).select().single()
  if (error) throw error
  return data
}

export async function deleteAnswer(id) {
  if (!isSupabaseAvailable()) throw new Error('Нет связи с сервером')
  const { error } = await supabase.from('quiz_answers').delete().eq('id', id)
  if (error) throw error
}

import { supabase, isSupabaseAvailable } from '@/lib/supabase'
import { getRecentGuests } from './guests'

/** Уровень экстрима 1–3 по параметру «Экспериментальность» гостя (0–10): 0–3→1, 4–6→2, 7–10→3. */
export function getExtremenessLevel(guest) {
  const v = Number(guest?.extremeness)
  if (Number.isNaN(v) || v < 0) return 2
  if (v <= 3) return 1
  if (v <= 6) return 2
  return 3
}

const EXTREMENESS_LEVEL_NAMES = { 1: 'Лёгкий', 2: 'Медиум', 3: 'Экстремальный' }
export function getExtremenessLevelName(level) {
  return EXTREMENESS_LEVEL_NAMES[level] ?? 'Медиум'
}

const PLANET_PREFIXES = ['Планета', 'Сектор', 'Колония', 'Объект']
const PLANET_SUFFIXES = ['Хаос', 'Квазар', 'Имбирь', 'Васаби', 'Нейтрино', 'Пульсар', 'Вектор', 'Импульс']
const TASK_TEXTS = [
  'Изобразить рождение сверхновой',
  'Синхронно пройтись как крабы',
  'За 30 секунд придумать гимн планеты',
  'Выбрать лидера телепатией',
  'Станцевать как сломанные андроиды',
  'Воспроизвести звук чёрной дыры',
  'Построить пирамиду из тел',
  'Показать эволюцию вида за 60 секунд',
]

function randomName() {
  const prefix = PLANET_PREFIXES[Math.floor(Math.random() * PLANET_PREFIXES.length)]
  const suffix = PLANET_SUFFIXES[Math.floor(Math.random() * PLANET_SUFFIXES.length)]
  const num = Math.floor(Math.random() * 99) + 1
  const tail = ['', '-Prime', '-7', '-X'][Math.floor(Math.random() * 4)]
  return `${prefix} ${suffix}-${num}${tail}`
}

export async function createPlanet() {
  const allGuests = await getRecentGuests(200)
  const activePlanetIds = await getActivePlanetMemberGuestIds()
  const available = allGuests.filter((g) => !activePlanetIds.has(g.id))
  const count = Math.min(6, Math.max(3, available.length))
  const selected = available.sort(() => Math.random() - 0.5).slice(0, count)
  const name = randomName()

  if (isSupabaseAvailable() && supabase) {
    const { data: planet, error: planetError } = await supabase
      .from('planets')
      .insert({ name, status: 'active' })
      .select()
      .single()
    if (planetError) throw planetError
    await supabase.from('planet_members').insert(
      selected.map((g) => ({ planet_id: planet.id, guest_id: g.id }))
    )
    const taskText = TASK_TEXTS[Math.floor(Math.random() * TASK_TEXTS.length)]
    await supabase.from('planet_tasks').insert({ planet_id: planet.id, task_text: taskText, status: 'active' })
    return { planet, members: selected, taskText }
  }
  return {
    planet: { id: crypto.randomUUID(), name, status: 'active', created_at: new Date().toISOString() },
    members: selected,
    taskText: TASK_TEXTS[Math.floor(Math.random() * TASK_TEXTS.length)],
  }
}

async function getActivePlanetMemberGuestIds() {
  if (!isSupabaseAvailable() || !supabase) return new Set()
  const { data: activePlanets } = await supabase.from('planets').select('id').eq('status', 'active')
  if (!activePlanets?.length) return new Set()
  const { data: members } = await supabase
    .from('planet_members')
    .select('guest_id')
    .in('planet_id', activePlanets.map((p) => p.id))
  return new Set((members ?? []).map((m) => m.guest_id))
}

/** Множество guest_id, которые уже в какой-либо активной планете (для исключения из кружков рас). */
export async function getGuestsInActivePlanetsIds() {
  return getActivePlanetMemberGuestIds()
}

export async function assignPlanetTask(planetId, taskText) {
  if (!isSupabaseAvailable() || !supabase) return null
  const text = taskText || TASK_TEXTS[Math.floor(Math.random() * TASK_TEXTS.length)]
  const { data, error } = await supabase
    .from('planet_tasks')
    .insert({ planet_id: planetId, task_text: text, status: 'active' })
    .select()
    .single()
  if (error) throw error
  return data
}

/** Загрузить гостей по id (с races при наличии таблицы). */
async function fetchGuestsByIds(guestIds) {
  if (!guestIds?.length) return []
  let res = await supabase.from('guests').select('*, races(id, name, slug)').in('id', guestIds)
  if (res.error) {
    res = await supabase.from('guests').select('*').in('id', guestIds)
  }
  if (res.error) throw res.error
  return res.data ?? []
}

function mapPlanetWithMembersAndTask(planet, members, tasks, guests) {
  const guestIds = (members ?? []).map((m) => m.guest_id)
  const guestMap = new Map((guests ?? []).map((g) => [g.id, g]))
  const list = guestIds.map((id) => guestMap.get(id)).filter(Boolean)
  const normalized = list.map((g) => {
    const race = g.races ? (Array.isArray(g.races) ? g.races[0] : g.races) : null
    const { races: _, ...rest } = g
    return { ...rest, race: race ? { id: race.id, name: race.name, slug: race.slug } : null }
  })
  return {
    ...planet,
    members: normalized,
    task: tasks?.[0] ?? null,
  }
}

export async function getActivePlanet() {
  if (!isSupabaseAvailable() || !supabase) return null
  const { data: planet, error } = await supabase
    .from('planets')
    .select('*')
    .eq('status', 'active')
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle()
  if (error) throw error
  if (!planet) return null
  const { data: members } = await supabase
    .from('planet_members')
    .select('guest_id')
    .eq('planet_id', planet.id)
  const { data: tasks } = await supabase
    .from('planet_tasks')
    .select('*')
    .eq('planet_id', planet.id)
    .eq('status', 'active')
    .order('created_at', { ascending: false })
    .limit(1)
  const guestIds = (members ?? []).map((m) => m.guest_id)
  const guestsRaw = await fetchGuestsByIds(guestIds)
  return mapPlanetWithMembersAndTask(planet, members, tasks, guestsRaw)
}

/** Завершённые планеты для отчётов: хронология, участники, задание, фото, время выполнения. */
export async function getCompletedPlanets(limit = 100) {
  if (!isSupabaseAvailable() || !supabase) return []
  const { data: planets, error } = await supabase
    .from('planets')
    .select('*')
    .eq('status', 'completed')
    .order('completed_at', { ascending: false, nullsFirst: false })
    .order('created_at', { ascending: false })
    .limit(limit)
  if (error) throw error
  if (!planets?.length) return []
  const planetIds = planets.map((p) => p.id)
  const [{ data: allMembers }, { data: allTasks }] = await Promise.all([
    supabase.from('planet_members').select('planet_id, guest_id').in('planet_id', planetIds),
    supabase.from('planet_tasks').select('*').in('planet_id', planetIds).eq('status', 'completed'),
  ])
  const guestIds = [...new Set((allMembers ?? []).map((m) => m.guest_id))]
  const guestsRaw = await fetchGuestsByIds(guestIds)
  return planets.map((planet) => {
    const members = (allMembers ?? []).filter((m) => m.planet_id === planet.id)
    const tasks = (allTasks ?? []).filter((t) => t.planet_id === planet.id).sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
    return mapPlanetWithMembersAndTask(planet, members, tasks, guestsRaw)
  })
}

/** Все активные планеты (для режима тамады — несколько групп). */
export async function getActivePlanets() {
  if (!isSupabaseAvailable() || !supabase) return []
  const { data: planets, error } = await supabase
    .from('planets')
    .select('*')
    .eq('status', 'active')
    .order('created_at', { ascending: false })
  if (error) throw error
  if (!planets?.length) return []
  const planetIds = planets.map((p) => p.id)
  const [{ data: allMembers }, { data: allTasks }] = await Promise.all([
    supabase.from('planet_members').select('planet_id, guest_id').in('planet_id', planetIds),
    supabase.from('planet_tasks').select('*').in('planet_id', planetIds).eq('status', 'active'),
  ])
  const guestIds = [...new Set((allMembers ?? []).map((m) => m.guest_id))]
  const guestsRaw = await fetchGuestsByIds(guestIds)
  return planets.map((planet) => {
    const members = (allMembers ?? []).filter((m) => m.planet_id === planet.id)
    const tasks = (allTasks ?? []).filter((t) => t.planet_id === planet.id).sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
    return mapPlanetWithMembersAndTask(planet, members, tasks, guestsRaw)
  })
}

export async function completePlanet(planetId) {
  if (!isSupabaseAvailable() || !supabase) return
  const completedAt = new Date().toISOString()
  await supabase.from('planets').update({ status: 'completed', completed_at: completedAt }).eq('id', planetId)
  await supabase.from('planet_tasks').update({ status: 'completed' }).eq('planet_id', planetId)
}

/** Множество guest_id, у которых есть выполненное задание (участник завершённой планеты). Для бейджа на табло/бариста. */
export async function getGuestIdsWithCompletedTask() {
  if (!isSupabaseAvailable() || !supabase) return new Set()
  const { data: planets } = await supabase.from('planets').select('id').eq('status', 'completed')
  if (!planets?.length) return new Set()
  const { data: members } = await supabase
    .from('planet_members')
    .select('guest_id')
    .in('planet_id', planets.map((p) => p.id))
  return new Set((members ?? []).map((m) => m.guest_id))
}

/** Заменить задание у активной планеты (новый текст и сложность; уровень экстрима сохраняется). */
export async function replacePlanetTask(planetId, taskText, difficulty) {
  if (!isSupabaseAvailable() || !supabase) return
  const { error } = await supabase
    .from('planet_tasks')
    .update({ task_text: taskText, difficulty: difficulty != null ? Math.min(5, Math.max(1, Number(difficulty))) : null })
    .eq('planet_id', planetId)
    .eq('status', 'active')
  if (error) throw error
}

/** Завершить планету с прикреплённым фото (photo_url уже записан или передаётся). */
export async function completePlanetWithPhoto(planetId, photoUrl) {
  if (!isSupabaseAvailable() || !supabase) return
  const completedAt = new Date().toISOString()
  await supabase
    .from('planets')
    .update({ status: 'completed', photo_url: photoUrl ?? undefined, completed_at: completedAt })
    .eq('id', planetId)
  await supabase.from('planet_tasks').update({ status: 'completed' }).eq('planet_id', planetId)
}

const PLANET_PHOTOS_BUCKET = 'planet-photos'

/** Загрузить фото планеты в Storage и вернуть public URL. Bucket должен существовать и быть public. */
export async function uploadPlanetPhoto(planetId, file) {
  if (!isSupabaseAvailable() || !supabase) throw new Error('Нет связи с сервером')
  const ext = file.name?.match(/\.[a-z0-9]+$/i)?.[0] || '.jpg'
  const path = `${planetId}/${Date.now()}${ext}`
  const { data, error } = await supabase.storage.from(PLANET_PHOTOS_BUCKET).upload(path, file, {
    cacheControl: '3600',
    upsert: false,
  })
  if (error) throw error
  const { data: urlData } = supabase.storage.from(PLANET_PHOTOS_BUCKET).getPublicUrl(data.path)
  return urlData.publicUrl
}

/**
 * Объединить гостей одной расы в планету и выдать задание (для тамады).
 * @param {string} raceName — название расы для отображения
 * @param {Array<{ id: string }>} guests — массив гостей (нужен .id)
 * @param {string} taskText — текст задания
 * @param {number} [taskDifficulty] — сложность 1–5 (для цвета планеты)
 * @returns {Promise<{ id, name, members, task, created_at, photo_url?, ... }>} созданная планета с участниками и заданием
 */
export async function createPlanetFromRace(raceName, guests, taskText, taskDifficulty) {
  const guestIds = guests.map((g) => g.id)
  if (guestIds.length === 0) throw new Error('Нужен хотя бы один гость')
  const name = `Раса: ${raceName}`
  const difficulty = taskDifficulty != null ? Math.min(5, Math.max(1, Number(taskDifficulty))) : null

  if (isSupabaseAvailable() && supabase) {
    const { data: planet, error: planetError } = await supabase
      .from('planets')
      .insert({ name, status: 'active' })
      .select()
      .single()
    if (planetError) throw planetError
    await supabase.from('planet_members').insert(
      guestIds.map((guest_id) => ({ planet_id: planet.id, guest_id }))
    )
    const taskPayload = { planet_id: planet.id, task_text: taskText, status: 'active' }
    if (difficulty != null) taskPayload.difficulty = difficulty
    const { data: taskRow } = await supabase
      .from('planet_tasks')
      .insert(taskPayload)
      .select()
      .single()
    const guestsRaw = await fetchGuestsByIds(guestIds)
    return mapPlanetWithMembersAndTask(
      planet,
      guestIds.map((guest_id) => ({ guest_id })),
      taskRow ? [taskRow] : [],
      guestsRaw
    )
  }
  return {
    id: crypto.randomUUID(),
    name,
    status: 'active',
    created_at: new Date().toISOString(),
    members: guests,
    task: { task_text: taskText, status: 'active' },
  }
}

/**
 * Создать планету по выбранным гостям и уровню экстрима (1–3). Полностью ручной запуск тамады.
 * @param {Array<{ id: string }>} guests — массив гостей (нужен .id)
 * @param {string} taskText — текст задания
 * @param {number} extremenessLevel — 1 лёгкий, 2 медиум, 3 экстремально
 * @param {number} [taskDifficulty] — сложность 1–5 из tamada_tasks (для цвета)
 */
export async function createPlanetFromGuests(guests, taskText, extremenessLevel, taskDifficulty) {
  const guestIds = guests.map((g) => g.id)
  if (guestIds.length === 0) throw new Error('Нужен хотя бы один гость')
  const name = getExtremenessLevelName(extremenessLevel)
  const difficulty = taskDifficulty != null ? Math.min(5, Math.max(1, Number(taskDifficulty))) : (extremenessLevel === 1 ? 1 : extremenessLevel === 2 ? 3 : 5)

  if (isSupabaseAvailable() && supabase) {
    const { data: planet, error: planetError } = await supabase
      .from('planets')
      .insert({ name, status: 'active' })
      .select()
      .single()
    if (planetError) throw planetError
    await supabase.from('planet_members').insert(
      guestIds.map((guest_id) => ({ planet_id: planet.id, guest_id }))
    )
    const { data: taskRow } = await supabase
      .from('planet_tasks')
      .insert({ planet_id: planet.id, task_text: taskText, status: 'active', difficulty })
      .select()
      .single()
    const guestsRaw = await fetchGuestsByIds(guestIds)
    return mapPlanetWithMembersAndTask(
      planet,
      guestIds.map((guest_id) => ({ guest_id })),
      taskRow ? [taskRow] : [],
      guestsRaw
    )
  }
  return {
    id: crypto.randomUUID(),
    name,
    status: 'active',
    created_at: new Date().toISOString(),
    members: guests,
    task: { task_text: taskText, status: 'active', difficulty },
  }
}

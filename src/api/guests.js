import { supabase, isSupabaseAvailable } from '@/lib/supabase'
import * as idb from '@/lib/idb'

function isSchemaCacheError(e) {
  const msg = e?.message || ''
  return /schema cache|last_registration_at|column.*not found/i.test(msg)
}

export async function createGuest(data) {
  if (isSupabaseAvailable()) {
    const payload = {
      callsign: data.callsign.trim().toUpperCase(),
      avatar_url: data.avatar_url ?? null,
      allergies: Array.isArray(data.allergies) ? data.allergies : (data.allergies ? [data.allergies] : []),
      last_registration_at: new Date().toISOString(),
    }
    if (data.sweetness != null) payload.sweetness = data.sweetness
    if (data.bitterness != null) payload.bitterness = data.bitterness
    if (data.intensity != null) payload.intensity = data.intensity
    if (data.extremeness != null) payload.extremeness = data.extremeness
    if (data.race_id != null) payload.race_id = data.race_id
    let { data: guest, error } = await supabase
      .from('guests')
      .insert(payload)
      .select()
      .single()
    if (error && isSchemaCacheError(error)) {
      const { last_registration_at: _, ...payloadWithoutLra } = payload
      const retry = await supabase.from('guests').insert(payloadWithoutLra).select().single()
      if (retry.error) throw retry.error
      return retry.data
    }
    if (error) throw error
    return guest
  }
  const id = crypto.randomUUID()
  const guest = {
    id,
    callsign: data.callsign.trim().toUpperCase(),
    avatar_url: data.avatar_url ?? null,
    allergies: Array.isArray(data.allergies) ? data.allergies : (data.allergies ? [data.allergies] : []),
    sweetness: data.sweetness ?? null,
    bitterness: data.bitterness ?? null,
    intensity: data.intensity ?? null,
    extremeness: data.extremeness ?? null,
    race_id: data.race_id ?? null,
    created_at: new Date().toISOString(),
  }
  await idb.saveGuestOffline(guest)
  await idb.addPendingSync('createGuest', guest)
  return guest
}

export async function updateGuest(id, data) {
  if (isSupabaseAvailable()) {
    const payload = { ...data, last_registration_at: new Date().toISOString() }
    let { data: guest, error } = await supabase
      .from('guests')
      .update(payload)
      .eq('id', id)
      .select()
      .single()
    if (error && isSchemaCacheError(error)) {
      const { last_registration_at: _, ...payloadWithoutLra } = payload
      const retry = await supabase.from('guests').update(payloadWithoutLra).eq('id', id).select().single()
      if (retry.error) throw retry.error
      return retry.data
    }
    if (error) throw error
    return guest
  }
  await idb.addPendingSync('updateGuest', { id, data })
  return { id, ...data }
}

function guestWithRace(row) {
  if (!row) return null
  const race = row.races ? (Array.isArray(row.races) ? row.races[0] : row.races) : null
  const { races: _, ...rest } = row
  return { ...rest, race: race ? { id: race.id, name: race.name, slug: race.slug } : null }
}

export async function getGuestByCallsign(callsign) {
  const normalized = String(callsign).trim().toUpperCase()
  if (isSupabaseAvailable()) {
    let res = await supabase.from('guests').select('*, races(id, name, slug)').ilike('callsign', normalized).maybeSingle()
    if (res.error) {
      res = await supabase.from('guests').select('*').ilike('callsign', normalized).maybeSingle()
    }
    if (res.error) throw res.error
    if (!res.data) return null
    return guestWithRace(res.data)
  }
  const db = await idb.getDB()
  const all = await db.getAll(idb.STORE_GUESTS)
  return all.find((g) => g.callsign.toUpperCase() === normalized) ?? null
}

export async function getRecentGuests(limit = 20) {
  if (isSupabaseAvailable()) {
    const { data, error } = await supabase
      .from('guests')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(limit)
    if (error) throw error
    return data ?? []
  }
  const db = await idb.getDB()
  const all = await db.getAll(idb.STORE_GUESTS)
  return all
    .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
    .slice(0, limit)
}

/** Все гости (для админки участников) */
export async function getAllGuests(limit = 500) {
  if (isSupabaseAvailable()) {
    let res = await supabase.from('guests').select('*, races(id, name, slug)').order('created_at', { ascending: false }).limit(limit)
    if (res.error) {
      res = await supabase.from('guests').select('*').order('created_at', { ascending: false }).limit(limit)
    }
    if (res.error) throw res.error
    return (res.data ?? []).map(guestWithRace)
  }
  const db = await idb.getDB()
  const all = await db.getAll(idb.STORE_GUESTS)
  return all.sort((a, b) => new Date(b.created_at) - new Date(a.created_at)).slice(0, limit)
}

/** Один гость по id (полная информация для админки) */
export async function getGuestById(id) {
  if (!id) return null
  if (isSupabaseAvailable()) {
    let res = await supabase.from('guests').select('*, races(id, name, slug)').eq('id', id).maybeSingle()
    if (res.error) {
      res = await supabase.from('guests').select('*').eq('id', id).maybeSingle()
    }
    if (res.error) throw res.error
    if (!res.data) return null
    return guestWithRace(res.data)
  }
  const db = await idb.getDB()
  return (await db.get(idb.STORE_GUESTS, id)) ?? null
}

/** Удалить гостя (каскадно удалятся заказы, планеты и т.д.) */
export async function deleteGuest(id) {
  if (isSupabaseAvailable()) {
    const { error } = await supabase.from('guests').delete().eq('id', id)
    if (error) throw error
    return
  }
  throw new Error('Удаление гостя возможно только при подключении к серверу')
}

export function subscribeRecentGuests(callback) {
  if (!isSupabaseAvailable() || !supabase) return () => {}
  const channel = supabase
    .channel('guests-changes')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'guests' }, () => {
      getRecentGuests(20).then(callback)
    })
    .subscribe()
  return () => supabase.removeChannel(channel)
}

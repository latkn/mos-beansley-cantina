import { supabase, isSupabaseAvailable } from '@/lib/supabase'

export async function createOrder(guestId, coffee) {
  if (!isSupabaseAvailable()) {
    throw new Error('Для заказа нужна сеть')
  }
  const { data, error } = await supabase
    .from('coffee_orders')
    .insert({
      guest_id: guestId,
      coffee_id: coffee.id ?? null,
      coffee_name: coffee.name ?? 'Кофе',
      status: 'pending',
    })
    .select()
    .single()
  if (error) throw error
  return data
}

const ORDERS_SELECT_FULL = `
  id,
  guest_id,
  coffee_id,
  coffee_name,
  status,
  created_at,
  prepared_at,
  guests ( id, callsign, avatar_url, allergies, sweetness, bitterness, intensity, extremeness, race_id, barista_note, races ( id, name, slug ) ),
  coffee_menu ( prep_instructions, image_url )
`
const ORDERS_SELECT_MINIMAL = `
  id,
  guest_id,
  coffee_id,
  coffee_name,
  status,
  created_at,
  prepared_at,
  guests ( id, callsign, avatar_url, allergies, sweetness, bitterness, intensity, extremeness ),
  coffee_menu ( prep_instructions, image_url )
`

function normalizeOrderRow(row) {
  const guestRef = (r) => (Array.isArray(r.guests) ? r.guests[0] : r.guests)
  const coffeeRef = (r) => (Array.isArray(r.coffee_menu) ? r.coffee_menu[0] : r.coffee_menu)
  const g = guestRef(row)
  const coffee = coffeeRef(row)
  const raceRef = (guest) => (guest?.races ? (Array.isArray(guest.races) ? guest.races[0] : guest.races) : null)
  const race = g ? raceRef(g) : null
  const allergies = Array.isArray(g?.allergies) ? g.allergies : (g?.allergies ? [g.allergies] : [])
  const guestClean = g ? { ...g, allergies, race: race ? { id: race.id, name: race.name, slug: race.slug } : null } : null
  if (guestClean && 'races' in guestClean) delete guestClean.races
  return {
    id: row.id,
    guest_id: row.guest_id,
    coffee_id: row.coffee_id,
    coffee_name: row.coffee_name,
    prep_instructions: coffee?.prep_instructions ?? null,
    image_url: coffee?.image_url ?? null,
    status: row.status,
    created_at: row.created_at,
    prepared_at: row.prepared_at,
    guest: guestClean,
    callsign: g?.callsign ?? '?',
    allergies,
  }
}

async function fetchOrdersByStatus(status) {
  if (!isSupabaseAvailable()) return []
  const res = await supabase
    .from('coffee_orders')
    .select(ORDERS_SELECT_FULL)
    .eq('status', status)
    .order(status === 'pending' ? 'created_at' : 'prepared_at', { ascending: true })
  let data = res.data
  let error = res.error
  if (error) {
    const fallback = await supabase
      .from('coffee_orders')
      .select(ORDERS_SELECT_MINIMAL)
      .eq('status', status)
      .order(status === 'pending' ? 'created_at' : 'prepared_at', { ascending: true })
    data = fallback.data
    error = fallback.error
  }
  if (error) throw error
  return (data ?? []).map(normalizeOrderRow)
}

export async function getPendingOrders() {
  return fetchOrdersByStatus('pending')
}

/** Заказы в очереди (pending + ready) — для кружков рас в режиме тамады (участник не исчезает при ready). */
export async function getOrdersInQueue() {
  if (!isSupabaseAvailable()) return []
  let res = await supabase
    .from('coffee_orders')
    .select(ORDERS_SELECT_FULL)
    .in('status', ['pending', 'ready'])
    .order('created_at', { ascending: true })
  if (res.error) {
    res = await supabase
      .from('coffee_orders')
      .select(ORDERS_SELECT_MINIMAL)
      .in('status', ['pending', 'ready'])
      .order('created_at', { ascending: true })
  }
  if (res.error) throw res.error
  return (res.data ?? []).map(normalizeOrderRow)
}

export async function getReadyForPickupOrders() {
  return fetchOrdersByStatus('ready')
}

export async function markOrderReady(orderId) {
  if (!isSupabaseAvailable()) throw new Error('Нет связи с сервером')
  const { data, error } = await supabase
    .from('coffee_orders')
    .update({ status: 'ready', prepared_at: new Date().toISOString() })
    .eq('id', orderId)
    .select()
    .single()
  if (error) throw error
  return data
}

export async function markOrderPickedUp(orderId) {
  if (!isSupabaseAvailable()) throw new Error('Нет связи с сервером')
  const { data, error } = await supabase
    .from('coffee_orders')
    .update({ status: 'picked_up' })
    .eq('id', orderId)
    .select()
    .single()
  if (error) throw error
  return data
}

/** Обновить напиток в заказе (бариста выбрал другой из топ-3) */
export async function updateOrderCoffee(orderId, coffeeId, coffeeName) {
  if (!isSupabaseAvailable()) throw new Error('Нет связи с сервером')
  const { data, error } = await supabase
    .from('coffee_orders')
    .update({ coffee_id: coffeeId ?? null, coffee_name: coffeeName ?? 'Кофе' })
    .eq('id', orderId)
    .select()
    .single()
  if (error) throw error
  return data
}

/** Все заказы гостя (история) с данными напитка для карточки */
export async function getOrdersByGuestId(guestId) {
  if (!guestId || !isSupabaseAvailable()) return []
  const { data, error } = await supabase
    .from('coffee_orders')
    .select(`
      id,
      coffee_id,
      coffee_name,
      status,
      created_at,
      prepared_at,
      coffee_menu ( name, description, image_url )
    `)
    .eq('guest_id', guestId)
    .order('created_at', { ascending: false })
  if (error) throw error
  const coffeeRef = (row) => (Array.isArray(row.coffee_menu) ? row.coffee_menu[0] : row.coffee_menu)
  return (data ?? []).map((row) => {
    const coffee = coffeeRef(row)
    return {
      id: row.id,
      coffee_id: row.coffee_id,
      coffee_name: row.coffee_name || coffee?.name,
      status: row.status,
      created_at: row.created_at,
      prepared_at: row.prepared_at,
      description: coffee?.description ?? null,
      image_url: coffee?.image_url ?? null,
    }
  })
}

/** ID напитков, которые гость уже пробовал (по прошлым заказам). excludeOrderId — не учитывать этот заказ (текущий). */
export async function getGuestTriedCoffeeIds(guestId, excludeOrderId = null) {
  if (!guestId || !isSupabaseAvailable()) return []
  let q = supabase
    .from('coffee_orders')
    .select('id, coffee_id')
    .eq('guest_id', guestId)
    .not('coffee_id', 'is', null)
  if (excludeOrderId) q = q.neq('id', excludeOrderId)
  const { data, error } = await q
  if (error) throw error
  const ids = [...new Set((data ?? []).map((row) => row.coffee_id).filter(Boolean))]
  return ids
}

/** Заказы гостя с профилем напитка (для графика предпочтений по времени) — по возрастанию даты */
export async function getOrdersWithDrinkProfileByGuestId(guestId) {
  if (!guestId || !isSupabaseAvailable()) return []
  const { data, error } = await supabase
    .from('coffee_orders')
    .select(`
      id,
      coffee_name,
      created_at,
      coffee_menu ( sweetness, bitterness, intensity, extremeness )
    `)
    .eq('guest_id', guestId)
    .order('created_at', { ascending: true })
  if (error) throw error
  const coffeeRef = (row) => (Array.isArray(row.coffee_menu) ? row.coffee_menu[0] : row.coffee_menu)
  return (data ?? []).map((row) => {
    const coffee = coffeeRef(row)
    const def = (v) => (v != null && !Number.isNaN(Number(v)) ? Number(v) : 5)
    return {
      id: row.id,
      coffee_name: row.coffee_name,
      created_at: row.created_at,
      sweetness: def(coffee?.sweetness),
      bitterness: def(coffee?.bitterness),
      intensity: def(coffee?.intensity),
      extremeness: def(coffee?.extremeness),
    }
  })
}

/** Готовые заказы по списку guest_id (для табло) */
export async function getReadyOrdersByGuestIds(guestIds) {
  if (!guestIds?.length || !isSupabaseAvailable()) return {}
  const { data, error } = await supabase
    .from('coffee_orders')
    .select('guest_id, id, coffee_name, prepared_at')
    .eq('status', 'ready')
    .in('guest_id', guestIds)
    .order('prepared_at', { ascending: false })
  if (error) throw error
  const byGuest = {}
  for (const row of data ?? []) {
    if (!byGuest[row.guest_id]) byGuest[row.guest_id] = []
    byGuest[row.guest_id].push(row)
  }
  return byGuest
}

export function subscribeOrders(callback) {
  if (!isSupabaseAvailable() || !supabase) return () => {}
  const channel = supabase
    .channel('orders-changes')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'coffee_orders' }, () => {
      callback()
    })
    .subscribe()
  return () => supabase.removeChannel(channel)
}

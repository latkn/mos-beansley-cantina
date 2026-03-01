import { supabase, isSupabaseAvailable } from '@/lib/supabase'

/** Начало сегодняшнего дня по UTC (для фильтра «за сегодня») */
function startOfTodayUTC() {
  const d = new Date()
  d.setUTCHours(0, 0, 0, 0)
  return d.toISOString()
}

/**
 * Статистика по заказам: сварено за сегодня, всего, по типам кофе.
 * «Сварено» = заказы со статусом ready или picked_up.
 */
export async function getOrderStats() {
  if (!isSupabaseAvailable()) {
    return {
      todayBrewed: 0,
      totalBrewed: 0,
      byCoffee: [],
    }
  }

  const todayStart = startOfTodayUTC()

  const { data: orders, error } = await supabase
    .from('coffee_orders')
    .select('id, coffee_name, status, prepared_at')
    .in('status', ['ready', 'picked_up'])

  if (error) {
    console.error(error)
    return { todayBrewed: 0, totalBrewed: 0, byCoffee: [] }
  }

  const list = orders ?? []
  const totalBrewed = list.length
  const todayBrewed = list.filter((o) => o.prepared_at && o.prepared_at >= todayStart).length

  const byCoffeeMap = {}
  for (const o of list) {
    const name = o.coffee_name || 'Без названия'
    byCoffeeMap[name] = (byCoffeeMap[name] || 0) + 1
  }

  const byCoffee = Object.entries(byCoffeeMap)
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count)

  return {
    todayBrewed,
    totalBrewed,
    byCoffee,
  }
}

/**
 * Сброс статистики: удаление всех заказов со статусом ready или picked_up.
 * Требует подтверждения на клиенте.
 */
export async function resetOrderStats() {
  if (!isSupabaseAvailable()) {
    throw new Error('Нет доступа к базе')
  }
  const { error } = await supabase
    .from('coffee_orders')
    .delete()
    .in('status', ['ready', 'picked_up'])
  if (error) throw error
}

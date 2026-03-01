import { supabase, isSupabaseAvailable } from '@/lib/supabase'

/** Список всех рас (для редакторов и отображения). */
export async function getRaces() {
  if (!isSupabaseAvailable()) return []
  const { data, error } = await supabase
    .from('races')
    .select('id, name, slug, description, sort_order, min_in_queue_for_alert')
    .order('sort_order', { ascending: true })
  if (error) throw error
  return data ?? []
}

/** Одна раса по slug. */
export async function getRaceBySlug(slug) {
  if (!isSupabaseAvailable()) return null
  const { data, error } = await supabase
    .from('races')
    .select('*')
    .eq('slug', slug)
    .maybeSingle()
  if (error) throw error
  return data
}

/** Одна раса по id. */
export async function getRaceById(id) {
  if (!id || !isSupabaseAvailable()) return null
  const { data, error } = await supabase
    .from('races')
    .select('*')
    .eq('id', id)
    .maybeSingle()
  if (error) throw error
  return data
}

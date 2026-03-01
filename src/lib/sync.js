import { isSupabaseAvailable } from '@/lib/supabase'
import { getPendingSync, removePendingSync } from './idb'

/**
 * При восстановлении сети пытаемся отправить накопленные действия в Supabase.
 * В MVP обрабатываем только createGuest (полный объект гостя в payload).
 */
export async function flushPendingSync() {
  if (!isSupabaseAvailable()) return
  const { supabase } = await import('@/lib/supabase')
  const pending = await getPendingSync()
  for (const item of pending) {
    try {
      if (item.action === 'createGuest' && item.payload) {
        await supabase.from('guests').upsert(
          {
            id: item.payload.id,
            callsign: item.payload.callsign,
            avatar_url: item.payload.avatar_url,
            allergies: item.payload.allergies ?? [],
            sweetness: item.payload.sweetness ?? null,
            bitterness: item.payload.bitterness ?? null,
            intensity: item.payload.intensity ?? null,
            extremeness: item.payload.extremeness ?? null,
          },
          { onConflict: 'id' }
        )
      }
      await removePendingSync(item.id)
    } catch (e) {
      console.warn('Sync item failed', item.id, e)
    }
  }
}

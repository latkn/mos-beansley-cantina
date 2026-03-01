import { openDB } from 'idb'

const DB_NAME = 'cosmic-cantina'
const DB_VERSION = 1
const STORE_GUESTS = 'guests'
const STORE_PENDING = 'pending_sync'

export async function getDB() {
  return openDB(DB_NAME, DB_VERSION, {
    upgrade(db) {
      if (!db.objectStoreNames.contains(STORE_GUESTS)) {
        db.createObjectStore(STORE_GUESTS, { keyPath: 'id' })
      }
      if (!db.objectStoreNames.contains(STORE_PENDING)) {
        db.createObjectStore(STORE_PENDING, { keyPath: 'id', autoIncrement: true })
      }
    },
  })
}

export async function saveGuestOffline(guest) {
  const db = await getDB()
  await db.put(STORE_GUESTS, { ...guest, id: guest.id || crypto.randomUUID() })
}

export async function getGuestOffline(id) {
  const db = await getDB()
  return db.get(STORE_GUESTS, id)
}

export async function addPendingSync(action, payload) {
  const db = await getDB()
  await db.add(STORE_PENDING, { action, payload, createdAt: Date.now() })
}

export async function getPendingSync() {
  const db = await getDB()
  return db.getAll(STORE_PENDING)
}

export async function removePendingSync(id) {
  const db = await getDB()
  await db.delete(STORE_PENDING, id)
}

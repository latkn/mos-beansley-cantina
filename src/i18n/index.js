import { ref, computed } from 'vue'
import ru from './locales/ru.js'
import en from './locales/en.js'

const messages = { ru, en }

export const locale = ref('ru')

export function setLocale(code) {
  if (messages[code]) locale.value = code
}

export function useI18n() {
  const t = (key, params = {}) => {
    const parts = key.split('.')
    let value = messages[locale.value]
    for (const p of parts) {
      value = value?.[p]
    }
    if (typeof value !== 'string') return key
    return Object.keys(params).reduce((s, k) => s.replace(new RegExp(`\\{${k}\\}`, 'g'), params[k]), value)
  }
  return { t, locale: computed(() => locale.value), setLocale }
}

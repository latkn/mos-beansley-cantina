/**
 * Определение расы по профилю гостя (sweetness, bitterness, intensity, extremeness).
 * «Биометрия» при регистрации даёт профиль — по нему назначаем одну из 4 рас.
 * Центроиды в 4D (0–10): каждая раса имеет свой «идеальный» профиль.
 * Гость относится к расе с минимальной евклидовой дистанцией до центроида.
 */

/** Центроиды рас по slug: { sweetness, bitterness, intensity, extremeness } */
export const RACE_CENTROIDS = {
  vorloki: { sweetness: 8, bitterness: 2, intensity: 3, extremeness: 3 },   // сладкоежки
  keldari: { sweetness: 2, bitterness: 8, intensity: 6, extremeness: 2 },   // горечь, пуристы
  zorg: { sweetness: 4, bitterness: 4, intensity: 8, extremeness: 8 },      // экстремалы
  tauri: { sweetness: 5, bitterness: 5, intensity: 5, extremeness: 4 },    // баланс
}

const RACE_SLUGS = Object.keys(RACE_CENTROIDS)

function euclidean(a, b) {
  const s = (a.sweetness ?? 5) - (b.sweetness ?? 5)
  const bt = (a.bitterness ?? 5) - (b.bitterness ?? 5)
  const i = (a.intensity ?? 5) - (b.intensity ?? 5)
  const e = (a.extremeness ?? 5) - (b.extremeness ?? 5)
  return Math.sqrt(s * s + bt * bt + i * i + e * e)
}

/**
 * Возвращает slug расы, наиболее близкой к профилю.
 * @param profile { sweetness, bitterness, intensity, extremeness } (0–10)
 * @returns { string } slug расы (vorloki | keldari | zorg | tauri)
 */
export function getRaceSlugFromProfile(profile) {
  if (!profile) return 'tauri'
  let bestSlug = 'tauri'
  let bestDist = Infinity
  for (const slug of RACE_SLUGS) {
    const d = euclidean(profile, RACE_CENTROIDS[slug])
    if (d < bestDist) {
      bestDist = d
      bestSlug = slug
    }
  }
  return bestSlug
}

/**
 * При наличии списка рас из API — возвращает id расы по slug.
 * @param profile — профиль гостя
 * @param races — массив { id, slug, ... } из getRaces()
 * @returns { string | null } race_id или null
 */
export function getRaceIdFromProfile(profile, races) {
  const slug = getRaceSlugFromProfile(profile)
  const race = Array.isArray(races) ? races.find((r) => r.slug === slug) : null
  return race?.id ?? null
}

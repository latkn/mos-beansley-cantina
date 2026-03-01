/**
 * Расчёт профиля гостя по ответам на вопросы и подбор напитка по евклидовой дистанции.
 * Параметры: sweetness, bitterness, intensity, extremeness (0–10).
 */

const MIN_PARAM = 0
const MAX_PARAM = 10

/**
 * Вычисляет итоговый профиль по ответам.
 * answers: массив { answer: { sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta }, question: { weight } }
 * @returns {{ raw: { sweetness, bitterness, intensity, extremeness }, normalized: { sweetness, bitterness, intensity, extremeness } }}
 */
export function calculateProfileFromAnswers(answers) {
  let sweetness = 0
  let bitterness = 0
  let intensity = 0
  let extremeness = 0

  for (const { answer, question } of answers) {
    const w = Number(question?.weight ?? 1)
    sweetness += (Number(answer?.sweetness_delta ?? 0)) * w
    bitterness += (Number(answer?.bitterness_delta ?? 0)) * w
    intensity += (Number(answer?.intensity_delta ?? 0)) * w
    extremeness += (Number(answer?.extremeness_delta ?? 0)) * w
  }

  const raw = { sweetness, bitterness, intensity, extremeness }
  return {
    raw,
    normalized: normalizeToRange(raw),
  }
}

/**
 * Нормализует сырые суммы в диапазон 0–10.
 * Линейная нормализация: считаем, что типичный диапазон сумм примерно -15..+15 (5 вопросов * ±3).
 * Или просто clamp от 0 до 10 с центром в 5: mid=5 + scale * value, потом clamp.
 * По ТЗ: "нормализовать значения в диапазон 0–10, ограничить min/max".
 * Простой вариант: нормализуем так, чтобы 0 оставалось 0, а разброс укладывался в 0–10.
 * Используем: valueNorm = 5 + raw * 0.5 (примерно), затем clamp 0–10.
 * Более универсально: minRaw/maxRaw из конфига или эвристика. Для простоты: norm = 5 + raw * 0.33, clamp.
 */
export function normalizeToRange(raw) {
  // Коэффициент: при сумме ±9 (3 вопроса по ±3) получаем примерно ±3 по шкале → 2..8
  const scale = 0.4
  const center = 5
  const clamp = (v) => Math.min(MAX_PARAM, Math.max(MIN_PARAM, Math.round(center + v * scale)))

  return {
    sweetness: clamp(raw.sweetness),
    bitterness: clamp(raw.bitterness),
    intensity: clamp(raw.intensity),
    extremeness: clamp(raw.extremeness),
  }
}

/**
 * Евклидова дистанция между профилем гостя и профилем напитка.
 */
export function euclideanDistance(guestProfile, drink) {
  const s = (guestProfile.sweetness ?? 5) - (drink.sweetness ?? 5)
  const b = (guestProfile.bitterness ?? 5) - (drink.bitterness ?? 5)
  const i = (guestProfile.intensity ?? 5) - (drink.intensity ?? 5)
  const e = (guestProfile.extremeness ?? 5) - (drink.extremeness ?? 5)
  return Math.sqrt(s * s + b * b + i * i + e * e)
}

/** Минимальная длина совпадения по корню слова (избегаем ложных срабатываний) */
const ALLERGY_ROOT_LEN = 4

/**
 * Проверяет, совпадает ли ингредиент с аллергией (подстрока или общий корень слова).
 * Учитывает разные формы: "финики" / "финиковый" / "финиках".
 */
function ingredientMatchesAllergy(ingredient, allergy) {
  const i = String(ingredient ?? '').trim().toLowerCase()
  const a = String(allergy ?? '').trim().toLowerCase()
  if (!a) return false
  if (i.includes(a) || a.includes(i)) return true
  const iWords = i.split(/\s+/).filter(Boolean)
  const aWords = a.split(/\s+/).filter(Boolean)
  for (const aw of aWords) {
    if (aw.length < 3) continue
    const root = aw.length >= ALLERGY_ROOT_LEN ? aw.slice(0, ALLERGY_ROOT_LEN) : aw
    for (const iw of iWords) {
      if (iw.length < 3) continue
      if (iw.includes(aw) || aw.includes(iw)) return true
      if (iw.includes(root) || iw.slice(0, ALLERGY_ROOT_LEN) === root) return true
    }
  }
  return false
}

/**
 * Исключает напитки, содержащие ингредиенты из списка аллергий.
 * Учитываются подстроки и общий корень слова (например, финики / финиковый / финиках).
 */
export function filterByAllergies(drinks, allergies) {
  const list = Array.isArray(allergies) ? allergies : []
  if (!list.length) return drinks

  return drinks.filter((drink) => {
    const ingredients = Array.isArray(drink.ingredients) ? drink.ingredients : []
    for (const allergy of list) {
      const a = String(allergy ?? '').trim()
      if (!a) continue
      for (const ing of ingredients) {
        if (ingredientMatchesAllergy(ing, a)) return false
      }
    }
    return true
  })
}

/**
 * Выбирает до count напитков с минимальной дистанцией до профиля гостя.
 * @param {Object} guestProfile - { sweetness, bitterness, intensity, extremeness } (0–10)
 * @param {Array} drinks - массив напитков с полями sweetness, bitterness, intensity, extremeness
 * @param {Array} allergies - список аллергий для исключения по ингредиентам
 * @param {number} count - сколько напитков вернуть
 * @param {number} maxExtremeThreshold - опционально: не показывать напитки с extremeness > этого значения если у гостя low extremeness
 */
export function findBestDrinks(guestProfile, drinks, allergies = [], count = 3, maxExtremeThreshold = null) {
  let list = filterByAllergies(drinks, allergies)

  if (maxExtremeThreshold != null && guestProfile.extremeness < 5) {
    list = list.filter((d) => (d.extremeness ?? 5) <= maxExtremeThreshold)
  }

  const withDistance = list.map((drink) => ({
    drink,
    distance: euclideanDistance(guestProfile, drink),
  }))
  withDistance.sort((a, b) => a.distance - b.distance)
  return withDistance.slice(0, count).map((x) => x.drink)
}

/** Максимальная возможная дистанция в 4D при шкале 0–10 (разница по каждой оси до 10) */
const MAX_DISTANCE = Math.sqrt(4 * 10 * 10)

/**
 * Преобразует евклидову дистанцию в процент совпадения (0–100).
 * distance 0 → 100%, distance MAX_DISTANCE → 0%.
 */
export function distanceToMatchPercent(distance) {
  const clamped = Math.max(0, Math.min(MAX_DISTANCE, distance))
  return Math.round(100 - (clamped / MAX_DISTANCE) * 100)
}

/**
 * Возвращает до count напитков с минимальной дистанцией и процентом совпадения.
 * @returns {Array<{ drink: Object, distance: number, matchPercent: number }>}
 */
export function findBestDrinksWithScores(guestProfile, drinks, allergies = [], count = 3, maxExtremeThreshold = null) {
  let list = filterByAllergies(drinks, allergies)

  if (maxExtremeThreshold != null && guestProfile.extremeness < 5) {
    list = list.filter((d) => (d.extremeness ?? 5) <= maxExtremeThreshold)
  }

  const withDistance = list.map((drink) => ({
    drink,
    distance: euclideanDistance(guestProfile, drink),
  }))
  withDistance.sort((a, b) => a.distance - b.distance)
  return withDistance.slice(0, count).map((x) => ({
    drink: x.drink,
    distance: x.distance,
    matchPercent: distanceToMatchPercent(x.distance),
  }))
}

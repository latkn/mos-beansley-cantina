-- Обновление параметров профиля напитков (сладость, горечь, интенсивность, экспериментальность)
-- по составу и типу напитка. Выполнить в Supabase SQL Editor после загрузки меню.
-- Параметры 0–10: соответствуют логике подбора по квизу.

-- Базовое меню (schema / дефолт)
UPDATE coffee_menu SET sweetness = 2, bitterness = 7, intensity = 8, extremeness = 2 WHERE name = 'Эспрессо';
UPDATE coffee_menu SET sweetness = 1, bitterness = 6, intensity = 6, extremeness = 1 WHERE name = 'Американо';
UPDATE coffee_menu SET sweetness = 4, bitterness = 4, intensity = 5, extremeness = 2 WHERE name = 'Капучино';
UPDATE coffee_menu SET sweetness = 5, bitterness = 3, intensity = 4, extremeness = 2 WHERE name = 'Латте';
UPDATE coffee_menu SET sweetness = 4, bitterness = 4, intensity = 6, extremeness = 2 WHERE name = 'Флэт уайт';
UPDATE coffee_menu SET sweetness = 2, bitterness = 5, intensity = 5, extremeness = 3 WHERE name = 'Фильтр';
UPDATE coffee_menu SET sweetness = 2, bitterness = 5, intensity = 6, extremeness = 5 WHERE name = 'Колд брю';
UPDATE coffee_menu SET sweetness = 6, bitterness = 3, intensity = 4, extremeness = 4 WHERE name = 'Раф';
UPDATE coffee_menu SET sweetness = 7, bitterness = 3, intensity = 5, extremeness = 5 WHERE name = 'Аффогато';
UPDATE coffee_menu SET sweetness = 6, bitterness = 3, intensity = 4, extremeness = 7 WHERE name = 'Спешелти латте';

-- Коктейльная карта (по составу: сладость — сахар/мёд/финики/молоко; горечь — кофе без маскировки; интенсивность — крепость/специи; экспериментальность — необычные ингредиенты)
UPDATE coffee_menu SET sweetness = 2, bitterness = 5, intensity = 8, extremeness = 9 WHERE name = 'Том-ям кофе';
UPDATE coffee_menu SET sweetness = 8, bitterness = 3, intensity = 4, extremeness = 5 WHERE name = 'Кофе на финиках';
UPDATE coffee_menu SET sweetness = 2, bitterness = 5, intensity = 7, extremeness = 8 WHERE name = 'Кофе самбал';
UPDATE coffee_menu SET sweetness = 4, bitterness = 5, intensity = 7, extremeness = 7 WHERE name = 'Чили-какао-кофе';
UPDATE coffee_menu SET sweetness = 1, bitterness = 5, intensity = 9, extremeness = 9 WHERE name = 'Двойной ожог';
UPDATE coffee_menu SET sweetness = 3, bitterness = 4, intensity = 5, extremeness = 6 WHERE name = 'Мохито кофе';
UPDATE coffee_menu SET sweetness = 3, bitterness = 5, intensity = 5, extremeness = 5 WHERE name = 'Арабский кофе';
UPDATE coffee_menu SET sweetness = 2, bitterness = 5, intensity = 7, extremeness = 8 WHERE name = 'Ginger–Chili Cold Brew';
UPDATE coffee_menu SET sweetness = 4, bitterness = 4, intensity = 6, extremeness = 6 WHERE name = 'Ginger Espresso Shot';
UPDATE coffee_menu SET sweetness = 2, bitterness = 4, intensity = 5, extremeness = 6 WHERE name = 'Базилик';
UPDATE coffee_menu SET sweetness = 6, bitterness = 3, intensity = 5, extremeness = 6 WHERE name = 'Spicy Honey Latte';
UPDATE coffee_menu SET sweetness = 5, bitterness = 3, intensity = 4, extremeness = 5 WHERE name = 'Lime Cream Coffee';
UPDATE coffee_menu SET sweetness = 2, bitterness = 4, intensity = 6, extremeness = 6 WHERE name = 'Ginger Heat Coffee';
UPDATE coffee_menu SET sweetness = 6, bitterness = 4, intensity = 6, extremeness = 7 WHERE name = 'Cocoa Chili Mocha';
UPDATE coffee_menu SET sweetness = 4, bitterness = 4, intensity = 4, extremeness = 6 WHERE name = 'Basil Coffee Tonic (без тоника)';
UPDATE coffee_menu SET sweetness = 8, bitterness = 3, intensity = 4, extremeness = 5 WHERE name = 'Date Sweet Coffee';
UPDATE coffee_menu SET sweetness = 6, bitterness = 3, intensity = 4, extremeness = 5 WHERE name = 'Mint Cream Cold Coffee';

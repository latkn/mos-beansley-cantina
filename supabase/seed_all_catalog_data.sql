-- Единый скрипт сида: коктейльная карта, аллергены, вопросы для подбора напитков.
-- Выполнить в Supabase SQL Editor после schema.sql и миграций (races, tamada_tasks, is_galaxy_watcher и т.д.).
-- При повторном запуске старые данные в этих таблицах удаляются и вставляются заново.

-- Очистка (порядок из-за FK: ответы → вопросы, остальное независимо)
delete from quiz_answers;
delete from quiz_questions;
delete from coffee_menu;
delete from allergens;

-- ========== 1. Аллергены ==========
insert into allergens (label, sort_order) values
  ('Молоко', 0),
  ('Мёд', 1),
  ('Имбирь', 2),
  ('Чили / острый перец', 3),
  ('Цитрусовые', 4),
  ('Какао', 5),
  ('Специи', 6),
  ('Финики', 7),
  ('Травы (мята, базилик)', 8),
  ('Самбал / орехи / морепродукты', 9);

-- ========== 2. Коктейльная кофейная карта ==========
insert into coffee_menu (name, base_type, experimental_level, ingredients, is_available, description, prep_instructions, sweetness, bitterness, intensity, extremeness) values
  ('Том-ям кофе', 'espresso', 4, '["фильтр-кофе / эспрессо", "том ям концентрат", "лемонграсс", "чили"]', true, 'Шоты на эспрессо, шорты на колд брю', 'Заварить фильтр или эспрессо. Добавить том-ям концентрат, лемонграсс, чили. Перемешать.', 2, 5, 8, 9),
  ('Кофе на финиках', 'espresso', 3, '["финиковая паста", "эспрессо", "корица", "морская соль"]', true, 'опц: корица, щепоть соли', 'Финиковую пасту на дно стакана. Пролить эспрессо. Добавить щепотку корицы и морской соли по вкусу.', 8, 3, 4, 5),
  ('Кофе самбал', 'filter', 5, '["фильтр", "самбал"]', true, 'балийская приправа', 'Приготовить фильтр-кофе. Добавить самбал, размешать.', 2, 5, 7, 8),
  ('Чили-какао-кофе', 'espresso', 5, '["эспрессо", "цедра лайма", "микро-доза чили", "щепоть соли"]', true, null, 'Эспрессо + цедра лайма, микро-доза чили, щепоть соли. Аккуратно перемешать.', 4, 5, 7, 7),
  ('Двойной ожог', 'espresso', 6, '["эспрессо", "красный перец", "шрирача"]', true, null, 'Эспрессо, красный перец, шрирача. Смешать. Подавать сразу.', 1, 5, 9, 9),
  ('Мохито кофе', 'espresso', 4, '["лайм", "мята", "эспрессо"]', true, 'или фильтр', 'Лайм и мяту в стакан, слегка подавить. Добавить эспрессо или фильтр. Лёд по желанию.', 3, 4, 5, 6),
  ('Арабский кофе', 'filter', 3, '["жареные специи"]', true, null, 'Заварить кофе с жареными специями (кардамон и др. по рецепту).', 3, 5, 5, 5),
  ('Ginger–Chili Cold Brew', 'cold_brew', 5, '["cold brew", "свежий имбирный сок", "чили"]', true, null, 'Холодный колд брю + свежий имбирный сок + чили. Перемешать, подавать со льдом.', 2, 5, 7, 8),
  ('Ginger Espresso Shot', 'espresso', 4, '["эспрессо", "имбирный сок 3–5 капель", "щепоть соли", "лимон", "мед"]', true, 'опц: лимон', 'Эспрессо в шот. 3–5 капель имбирного сока, щепоть соли. Опционально лимон, мёд.', 4, 4, 6, 6),
  ('Базилик', 'espresso', 4, '["эспрессо", "базилик", "лимон"]', true, null, 'Базилик и лимон в стакан, слегка подавить. Пролить эспрессо. Перемешать.', 2, 4, 5, 6),
  ('Spicy Honey Latte', 'espresso', 4, '["кофе", "сухое молоко", "мёд", "чили"]', true, 'сухое молоко', 'Кофе + сухое молоко размешать. Добавить мёд и щепотку чили.', 6, 3, 5, 6),
  ('Lime Cream Coffee', 'espresso', 3, '["кофе", "сухое молоко", "сок лайма", "сахар"]', true, null, 'Кофе, сухое молоко, сок лайма, сахар. Смешать до однородности.', 5, 3, 4, 5),
  ('Ginger Heat Coffee', 'espresso', 4, '["кофе", "сухое молоко", "тёртый имбирь", "соль"]', true, null, 'Кофе + сухое молоко + тёртый имбирь + щепоть соли. Размешать.', 2, 4, 6, 6),
  ('Cocoa Chili Mocha', 'espresso', 5, '["кофе", "сухое молоко", "какао", "чили", "сахар"]', true, null, 'Кофе, сухое молоко, какао, щепотка чили, сахар. Всё смешать.', 6, 4, 6, 7),
  ('Basil Coffee Tonic (без тоника)', 'espresso', 4, '["кофе", "сухое молоко", "базилик", "лёд", "сахар"]', true, null, 'Кофе + сухое молоко + базилик + сахар. Подавать со льдом.', 4, 4, 4, 6),
  ('Date Sweet Coffee', 'espresso', 3, '["кофе", "сухое молоко", "финики", "корица"]', true, 'финики размять', 'Финики размять на дне. Кофе + сухое молоко + корица. Перемешать.', 8, 3, 4, 5),
  ('Mint Cream Cold Coffee', 'cold_brew', 4, '["холодный кофе", "сухое молоко", "мята", "мёд"]', true, null, 'Холодный кофе + сухое молоко + мята + мёд. Размешать, подавать холодным.', 6, 3, 4, 5);

-- ========== 3. Вопросы для подбора напитка ==========
-- 3.1 Базовые 3 вопроса (seed_quiz)
insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
  ('Какой уровень сладости предпочитаете?', true, 1, 0, false),
  ('Насколько интенсивный вкус вам по душе?', true, 1, 1, false),
  ('Готовы к нестандартным сочетаниям (пряности, чили, необычные добавки)?', true, 1.2, 2, false);

insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Без сладости, горький кофе', -2, 2, 1, 0, 0 from quiz_questions where text = 'Какой уровень сладости предпочитаете?' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Нейтрально', 0, 0, 0, 0, 1 from quiz_questions where text = 'Какой уровень сладости предпочитаете?' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Сладковатый, с сиропом или молоком', 2, -1, -1, 0, 2 from quiz_questions where text = 'Какой уровень сладости предпочитаете?' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Очень сладкий, десертный', 3, -2, -1, 1, 3 from quiz_questions where text = 'Какой уровень сладости предпочитаете?' limit 1;

insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Мягкий, лёгкий', 0, -1, -2, -1, 0 from quiz_questions where text = 'Насколько интенсивный вкус вам по душе?' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Средний', 0, 0, 0, 0, 1 from quiz_questions where text = 'Насколько интенсивный вкус вам по душе?' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Насыщенный, крепкий', 0, 1, 2, 0, 2 from quiz_questions where text = 'Насколько интенсивный вкус вам по душе?' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Максимально бодрящий', 0, 2, 3, 2, 3 from quiz_questions where text = 'Насколько интенсивный вкус вам по душе?' limit 1;

insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Только классика: эспрессо, американо, латте', 0, 0, 0, -2, 0 from quiz_questions where text = 'Готовы к нестандартным сочетаниям (пряности, чили, необычные добавки)?' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Можно что-то с пряностями или необычным вкусом', 0, 0, 0, 1, 1 from quiz_questions where text = 'Готовы к нестандартным сочетаниям (пряности, чили, необычные добавки)?' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Да, хочу попробовать чили, имбирь, том-ям и т.п.', 0, 1, 2, 4, 2 from quiz_questions where text = 'Готовы к нестандартным сочетаниям (пряности, чили, необычные добавки)?' limit 1;

-- 3.2 Смотрящий по галактике (seed_quiz_galaxy_watcher) — sort_order 10..19
insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Есть два трона в отсеке: на одном кристаллы точёные, на другом щупальца дрочёные. Куда сам сядешь, куда капитана посадишь?', true, 1, 10, true);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Сяду на кристаллы, капитана — на щупальца.', 0, 0, 0, 0, 0 from quiz_questions where is_galaxy_watcher = true and text like 'Есть два трона%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Пусть капитан выбирает, я постою.', 0, 0, 0, 0, 1 from quiz_questions where is_galaxy_watcher = true and text like 'Есть два трона%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Никуда не сяду, страшно.', 0, 0, 0, 0, 2 from quiz_questions where is_galaxy_watcher = true and text like 'Есть два трона%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Попрошу заменить мебель.', 0, 0, 0, 0, 3 from quiz_questions where is_galaxy_watcher = true and text like 'Есть два трона%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Разберу кристаллы — сделаю клинок, щупальца приручу — будет питомец-осьминог. Сам на трон, командира — рядом, пусть любуется адом.', 0, 0, 0, 4, 4 from quiz_questions where is_galaxy_watcher = true and text like 'Есть два трона%' limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Ты падаешь в капсуле: справа — лес ксенохуёв, слева — океан биоговна. Куда приземлишься?', true, 1, 11, true);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'В лес.', 0, 0, 0, 0, 0 from quiz_questions where is_galaxy_watcher = true and text like 'Ты падаешь в капсуле%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'В океан.', 0, 0, 0, 0, 1 from quiz_questions where is_galaxy_watcher = true and text like 'Ты падаешь в капсуле%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Закрою глаза и надеюсь на лучшее.', 0, 0, 0, 0, 2 from quiz_questions where is_galaxy_watcher = true and text like 'Ты падаешь в капсуле%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Попробую разбиться помягче.', 0, 0, 0, 0, 3 from quiz_questions where is_galaxy_watcher = true and text like 'Ты падаешь в капсуле%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'В каждом лесу есть просвет, в каждом океане — остров и свет.', 1, 0, 0, 3, 4 from quiz_questions where is_galaxy_watcher = true and text like 'Ты падаешь в капсуле%' limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Ты в карцере. На полу: энергетический батон и подозрительный инопланетный хуй. Что съешь, что в реактор засунешь?', true, 1, 12, true);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Съем батон.', 0, 0, 0, 0, 0 from quiz_questions where is_galaxy_watcher = true and text like 'Ты в карцере%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Не буду ничего трогать.', 0, 0, 0, 0, 1 from quiz_questions where is_galaxy_watcher = true and text like 'Ты в карцере%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Выброшу всё.', 0, 0, 0, 0, 2 from quiz_questions where is_galaxy_watcher = true and text like 'Ты в карцере%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Попробую всё съесть.', 0, 0, 0, 0, 3 from quiz_questions where is_galaxy_watcher = true and text like 'Ты в карцере%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Батон — в себя, хуй — в анализ. Пусть наука страдает, а я выбираюсь.', 0, 0, 0, 4, 4 from quiz_questions where is_galaxy_watcher = true and text like 'Ты в карцере%' limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Тебе говорят: либо в шлюз без скафандра, либо продашь свою планету. Твой ход?', true, 1, 13, true);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Продам планету.', 0, 0, 0, 0, 0 from quiz_questions where is_galaxy_watcher = true and text like 'Тебе говорят: либо в шлюз%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Выйду в шлюз.', 0, 0, 0, 0, 1 from quiz_questions where is_galaxy_watcher = true and text like 'Тебе говорят: либо в шлюз%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Пусть решает кто-то другой.', 0, 0, 0, 0, 2 from quiz_questions where is_galaxy_watcher = true and text like 'Тебе говорят: либо в шлюз%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Подпишу договор.', 0, 0, 0, 0, 3 from quiz_questions where is_galaxy_watcher = true and text like 'Тебе говорят: либо в шлюз%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Шлюз не открывается без кода, планета не продаётся без народа.', 0, 3, 0, 2, 4 from quiz_questions where is_galaxy_watcher = true and text like 'Тебе говорят: либо в шлюз%' limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Вопрос от надзирателя: лазер в глаз или зонд в жопу раз?', true, 1, 14, true);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Лазер.', 0, 0, 0, 0, 0 from quiz_questions where is_galaxy_watcher = true and text like 'Вопрос от надзирателя%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Зонд.', 0, 0, 0, 0, 1 from quiz_questions where is_galaxy_watcher = true and text like 'Вопрос от надзирателя%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Что быстрее.', 0, 0, 0, 0, 2 from quiz_questions where is_galaxy_watcher = true and text like 'Вопрос от надзирателя%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Я согласен.', 0, 0, 0, 0, 3 from quiz_questions where is_galaxy_watcher = true and text like 'Вопрос от надзирателя%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Что-то я тут одноглазых не вижу, а зонд — сначала сертификацию покажи-ка.', 0, 0, 0, 4, 4 from quiz_questions where is_galaxy_watcher = true and text like 'Вопрос от надзирателя%' limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Что выберешь: мыло с командного стола или хлеб из биореактора?', true, 1, 15, true);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Мыло.', 0, 0, 0, 0, 0 from quiz_questions where is_galaxy_watcher = true and text like 'Что выберешь: мыло%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Хлеб.', 0, 0, 0, 0, 1 from quiz_questions where is_galaxy_watcher = true and text like 'Что выберешь: мыло%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Ничего не буду есть.', 0, 0, 0, 0, 2 from quiz_questions where is_galaxy_watcher = true and text like 'Что выберешь: мыло%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Попрошу воды.', 0, 0, 0, 0, 3 from quiz_questions where is_galaxy_watcher = true and text like 'Что выберешь: мыло%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Стол не мыльница, реактор не хлебница.', 0, 2, 0, 2, 4 from quiz_questions where is_galaxy_watcher = true and text like 'Что выберешь: мыло%' limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Ты идёшь с кентом по астероиду. Вылезает ксенозмея и кусает его за хуй. Что делать будешь?', true, 1, 16, true);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Попробую отсосать яд.', 0, 0, 0, 0, 0 from quiz_questions where is_galaxy_watcher = true and text like 'Ты идёшь с кентом%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Убегу.', 0, 0, 0, 0, 1 from quiz_questions where is_galaxy_watcher = true and text like 'Ты идёшь с кентом%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Ничего не сделаю.', 0, 0, 0, 0, 2 from quiz_questions where is_galaxy_watcher = true and text like 'Ты идёшь с кентом%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Позову помощь.', 0, 0, 0, 0, 3 from quiz_questions where is_galaxy_watcher = true and text like 'Ты идёшь с кентом%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Если броня выше колена — не достанет, если ниже — сам справится, он ветеран десанта.', 0, 0, 0, 4, 4 from quiz_questions where is_galaxy_watcher = true and text like 'Ты идёшь с кентом%' limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Ты прикован к навигационному рычагу: вправо — твоя команда, влево — твой бывший командир. Кого раздавишь кораблём?', true, 1, 17, true);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Команду.', 0, 0, 0, 0, 0 from quiz_questions where is_galaxy_watcher = true and text like 'Ты прикован к навигационному%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Командира.', 0, 0, 0, 0, 1 from quiz_questions where is_galaxy_watcher = true and text like 'Ты прикован к навигационному%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Закрою глаза и потяну.', 0, 0, 0, 0, 2 from quiz_questions where is_galaxy_watcher = true and text like 'Ты прикован к навигационному%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Не знаю.', 0, 0, 0, 0, 3 from quiz_questions where is_galaxy_watcher = true and text like 'Ты прикован к навигационному%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Сначала выйду из наручников, потом отменю развилку.', 0, 3, 0, 3, 4 from quiz_questions where is_galaxy_watcher = true and text like 'Ты прикован к навигационному%' limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Тебе дают космическую баланду и сухой протеиновый кирпич. Утром находят кости. Ты живой. Откуда кости?', true, 1, 18, true);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Это чьи-то кости.', 0, 0, 0, 0, 0 from quiz_questions where is_galaxy_watcher = true and text like 'Тебе дают космическую баланду%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Я их съел.', 0, 0, 0, 0, 1 from quiz_questions where is_galaxy_watcher = true and text like 'Тебе дают космическую баланду%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Не знаю.', 0, 0, 0, 0, 2 from quiz_questions where is_galaxy_watcher = true and text like 'Тебе дают космическую баланду%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Это животные.', 0, 0, 0, 0, 3 from quiz_questions where is_galaxy_watcher = true and text like 'Тебе дают космическую баланду%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Игральные. Я играл на баланду.', 0, 2, 0, 2, 4 from quiz_questions where is_galaxy_watcher = true and text like 'Тебе дают космическую баланду%' limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('На стене рисуют ворота, на полу — плазменный шар. Говорят: забей гол.', true, 1, 19, true);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Пну шар.', 0, 0, 0, 0, 0 from quiz_questions where is_galaxy_watcher = true and text like 'На стене рисуют ворота%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Откажусь.', 0, 0, 0, 0, 1 from quiz_questions where is_galaxy_watcher = true and text like 'На стене рисуют ворота%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Не умею играть.', 0, 0, 0, 0, 2 from quiz_questions where is_galaxy_watcher = true and text like 'На стене рисуют ворота%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Спрошу правила.', 0, 0, 0, 0, 3 from quiz_questions where is_galaxy_watcher = true and text like 'На стене рисуют ворота%' limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Пусть сначала пас дадут, я не работаю в одиночку.', 1, 0, 0, 1, 4 from quiz_questions where is_galaxy_watcher = true and text like 'На стене рисуют ворота%' limit 1;

-- 3.3 Обычные вопросы — космическая тематика (seed_quiz_ordinary), sort_order 20..28
insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Корабль входит в атмосферу неизвестной планеты. Ты выбираешь режим посадки:', true, 1, 20, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Турбулентный спуск через грозовой фронт', 0, 0, 3, 2, 0 from quiz_questions where text like 'Корабль входит в атмосферу%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Точный расчёт по приборам', 0, 3, 0, 0, 1 from quiz_questions where text like 'Корабль входит в атмосферу%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Мягкое планирование на светящуюся равнину', 3, 0, 0, 0, 2 from quiz_questions where text like 'Корабль входит в атмосферу%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Рандомный вектор, смотрим куда вынесет', 0, 0, 0, 4, 3 from quiz_questions where text like 'Корабль входит в атмосферу%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('В космическом баре ты выбираешь:', true, 1, 21, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Самый странный пункт меню', 0, 0, 0, 3, 0 from quiz_questions where text like 'В космическом баре ты выбираешь%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Самый крепкий', 0, 2, 0, 0, 1 from quiz_questions where text like 'В космическом баре ты выбираешь%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Самый жгучий', 0, 0, 3, 0, 2 from quiz_questions where text like 'В космическом баре ты выбираешь%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Самый уютный', 2, 0, 0, 0, 3 from quiz_questions where text like 'В космическом баре ты выбираешь%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Твоя идеальная энергия — это:', true, 1, 22, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Резкий импульс', 0, 0, 2, 0, 0 from quiz_questions where text like 'Твоя идеальная энергия%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Глубокий устойчивый фон', 0, 2, 0, 0, 1 from quiz_questions where text like 'Твоя идеальная энергия%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Мягкая волна', 2, 0, 0, 0, 2 from quiz_questions where text like 'Твоя идеальная энергия%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Непредсказуемый всплеск', 0, 0, 0, 3, 3 from quiz_questions where text like 'Твоя идеальная энергия%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Какую планету выберешь для посадки?', true, 1, 23, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Жаркая пустыня', 0, 0, 2, 0, 0 from quiz_questions where text = 'Какую планету выберешь для посадки?' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Опасные джунгли', 0, 0, 0, 2, 1 from quiz_questions where text = 'Какую планету выберешь для посадки?' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Лёд и прозрачный воздух', 0, 2, 0, 0, 2 from quiz_questions where text = 'Какую планету выберешь для посадки?' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Тёплый вечер у костра', 2, 0, 0, 0, 3 from quiz_questions where text = 'Какую планету выберешь для посадки?' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Во время гиперскачка корабль начинает вибрировать. Ты:', true, 1, 24, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Усиливаешь мощность, пусть трясёт сильнее', 0, 0, 2, 2, 0 from quiz_questions where text like 'Во время гиперскачка корабль%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Анализируешь шум и устраняешь источник', 0, 2, 0, 0, 1 from quiz_questions where text like 'Во время гиперскачка корабль%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Успокаиваешь экипаж и включаешь мягкую подсветку', 2, 0, 0, 0, 2 from quiz_questions where text like 'Во время гиперскачка корабль%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Открываешь шлюз и смотришь, что будет', 0, 0, 0, 3, 3 from quiz_questions where text like 'Во время гиперскачка корабль%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Если бы ты был топливом для космического двигателя, ты был бы:', true, 1, 25, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Плазмой', 0, 0, 3, 0, 0 from quiz_questions where text like 'Если бы ты был топливом%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Тёмной материей', 0, 3, 0, 0, 1 from quiz_questions where text like 'Если бы ты был топливом%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Нектаром звезды', 3, 0, 0, 0, 2 from quiz_questions where text like 'Если бы ты был топливом%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Нестабильной сингулярностью', 0, 0, 0, 4, 3 from quiz_questions where text like 'Если бы ты был топливом%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Тебе предлагают обновить прошивку личности.', true, 1, 26, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Да, экспериментируем', 0, 0, 0, 3, 0 from quiz_questions where text like 'Тебе предлагают обновить прошивку%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Только если версия стабильная', 0, 2, 0, 0, 1 from quiz_questions where text like 'Тебе предлагают обновить прошивку%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Добавьте немного "остроты"', 0, 0, 2, 0, 2 from quiz_questions where text like 'Тебе предлагают обновить прошивку%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Пусть будет приятнее и мягче', 2, 0, 0, 0, 3 from quiz_questions where text like 'Тебе предлагают обновить прошивку%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Тебе дают неизвестный плод с другой планеты.', true, 1, 27, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Ем сразу', 0, 0, 0, 3, 0 from quiz_questions where text like 'Тебе дают неизвестный плод%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Нюхаю, изучаю, проверяю состав', 0, 2, 0, 0, 1 from quiz_questions where text like 'Тебе дают неизвестный плод%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Добавляю мёд, чтобы было безопаснее', 2, 0, 0, 0, 2 from quiz_questions where text like 'Тебе дают неизвестный плод%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Посыпаю перцем и пробую', 0, 0, 3, 0, 3 from quiz_questions where text like 'Тебе дают неизвестный плод%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Если система даст сбой, ты:', true, 1, 28, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Сохранишь протокол', 0, 2, 0, 0, 0 from quiz_questions where text like 'Если система даст сбой%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Перегрузишь реактор', 0, 0, 2, 0, 1 from quiz_questions where text like 'Если система даст сбой%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Успокоишь экипаж', 2, 0, 0, 0, 2 from quiz_questions where text like 'Если система даст сбой%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Посмотришь, что будет', 0, 0, 0, 3, 3 from quiz_questions where text like 'Если система даст сбой%' and is_galaxy_watcher = false limit 1;

-- 3.4 Дополнительные обычные вопросы (seed_quiz_ordinary_2), sort_order 30..44
insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('На экране — первый сигнал от незнакомой цивилизации. Ты:', true, 1, 30, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Включаю тёплый тон и приветственный протокол', 3, 0, 0, 0, 0 from quiz_questions where text like 'На экране — первый сигнал%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Запускаю полный анализ: язык, логика, угрозы', 0, 3, 0, 0, 1 from quiz_questions where text like 'На экране — первый сигнал%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Отвечаю тем же кодом — пусть разгадывают', 0, 0, 0, 3, 2 from quiz_questions where text like 'На экране — первый сигнал%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Сначала угощу их нашим кофе, потом поговорим', 2, -1, 0, 1, 3 from quiz_questions where text like 'На экране — первый сигнал%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('В спасательной капсуле места на одного. Рядом — раненый член экипажа. Ты:', true, 1, 31, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Остаюсь. Или вдвоём, или никого', 3, 0, 0, 0, 0 from quiz_questions where text like 'В спасательной капсуле места%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Считаю шансы: если он не выживет — один полетит, иначе оба погибнут', 0, 3, 0, 0, 1 from quiz_questions where text like 'В спасательной капсуле места%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Пробую втиснуться вдвоём — нарушу инструкцию, но попытка не пытка', 0, 0, 0, 3, 2 from quiz_questions where text like 'В спасательной капсуле места%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Укладываю его поудобнее и ищу ещё капсулы', 2, 1, 0, 0, 3 from quiz_questions where text like 'В спасательной капсуле места%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('На борту нашли артефакт: светится, гудит, назначение неизвестно. Ты:', true, 1, 32, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Ставлю в каюту — пусть создаёт уют', 2, 0, 0, 0, 0 from quiz_questions where text like 'На борту нашли артефакт%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'В изолированный отсек, полный скан и протокол безопасности', 0, 3, 0, 0, 1 from quiz_questions where text like 'На борту нашли артефакт%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Нажимаю все кнопки подряд — вдруг откроется портал', 0, 0, 0, 4, 2 from quiz_questions where text like 'На борту нашли артефакт%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Дарю капитану — пусть решает', 1, 1, 0, 0, 3 from quiz_questions where text like 'На борту нашли артефакт%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Часть экипажа объявила мятеж. Ты не с ними и не с капитаном. Твой ход:', true, 1, 33, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Собираю тех, кто хочет просто выжить — нейтральная зона', 2, 0, 0, 0, 0 from quiz_questions where text like 'Часть экипажа объявила мятеж%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Анализирую, чья сторона логичнее по уставу и шансам', 0, 3, 0, 0, 1 from quiz_questions where text like 'Часть экипажа объявила мятеж%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Предлагаю третью сторону: переизбрание капитана голосованием', 0, 0, 0, 3, 2 from quiz_questions where text like 'Часть экипажа объявила мятеж%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Иду к тем, кто обещает меньше крови', 2, -1, 0, 0, 3 from quiz_questions where text like 'Часть экипажа объявила мятеж%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('На разбитом корабле нашли чёрный ящик. В нём — признание в преступлении твоего друга. Ты:', true, 1, 34, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Сначала поговорю с другом — может, есть объяснение', 3, 0, 0, 0, 0 from quiz_questions where text like 'На разбитом корабле нашли чёрный ящик%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Передаю по регламенту. Дружба не отменяет закон', 0, 3, 0, 0, 1 from quiz_questions where text like 'На разбитом корабле нашли чёрный ящик%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Стираю запись и делаю вид, что ящик повреждён', 0, 0, 0, 4, 2 from quiz_questions where text like 'На разбитом корабле нашли чёрный ящик%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Показываю другу и прошу самому сдать отчёт', 2, 1, 0, 0, 3 from quiz_questions where text like 'На разбитом корабле нашли чёрный ящик%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Кто-то пронёс на борт инопланетное существо. Оно милое, но не прошло карантин. Ты:', true, 1, 35, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Прячу у себя — не отдам на уничтожение', 3, 0, 0, 1, 0 from quiz_questions where text like 'Кто-то пронёс на борт инопланетное%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Докладываю. Карантин существует не просто так', 0, 3, 0, 0, 1 from quiz_questions where text like 'Кто-то пронёс на борт инопланетное%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Предлагаю испытать на себе — если выживу, легализуем', 0, 0, 0, 4, 2 from quiz_questions where text like 'Кто-то пронёс на борт инопланетное%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Устраиваю тайный карантин в отсеке и наблюдаю', 1, 1, 0, 2, 3 from quiz_questions where text like 'Кто-то пронёс на борт инопланетное%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Разгерметизация. Скафандр один. Ты и напарник у люка. Ты:', true, 1, 36, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Отдаю скафандр. У него дети на Земле', 3, 0, 0, 0, 0 from quiz_questions where text like 'Разгерметизация. Скафандр один%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Надеваю. Я пилот — без меня все погибнут', 0, 3, 0, 0, 1 from quiz_questions where text like 'Разгерметизация. Скафандр один%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Делим кислород пополам и ползем к ближайшему отсеку вдвоём', 0, 0, 0, 4, 2 from quiz_questions where text like 'Разгерметизация. Скафандр один%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Жребий. Так честнее', 0, 2, 0, 0, 3 from quiz_questions where text like 'Разгерметизация. Скафандр один%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Перед долгим анабиозом можно загрузить сны: стандартный пакет «пляж» или свой сценарий. Ты:', true, 1, 37, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Свой: дом, семья, чай с печеньем', 3, 0, 0, 0, 0 from quiz_questions where text like 'Перед долгим анабиозом можно загрузить сны%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Стандартный пакет. Меньше сбоев, проверенная психология', 0, 3, 0, 0, 1 from quiz_questions where text like 'Перед долгим анабиозом можно загрузить сны%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Свой: полёт сквозь чёрную дыру и разговор с инопланетянами', 0, 0, 0, 4, 2 from quiz_questions where text like 'Перед долгим анабиозом можно загрузить сны%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Без снов — пусть мозг отдохнёт по-настоящему', 0, 2, 0, 1, 3 from quiz_questions where text like 'Перед долгим анабиозом можно загрузить сны%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Экипаж голосует: лететь к колонии (безопасно, скучно) или к руинам древней расы (интересно, опасно). Твой голос:', true, 1, 38, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Колония. Все устали, нужен отдых и стабильность', 3, 0, 0, 0, 0 from quiz_questions where text like 'Экипаж голосует: лететь к колонии%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Колония. Риск не оправдан без расчёта ресурсов и угроз', 0, 3, 0, 0, 1 from quiz_questions where text like 'Экипаж голосует: лететь к колонии%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Руины. Такую возможность не упускаем', 0, 0, 0, 4, 2 from quiz_questions where text like 'Экипаж голосует: лететь к колонии%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Руины, но с условием: сначала высаживаем тех, кто хочет в колонию', 2, 0, 0, 2, 3 from quiz_questions where text like 'Экипаж голосует: лететь к колонии%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Корабельный ИИ спрашивает: «Добавить эмоции в голос? Да / Нет / Случайный режим». Ты выбираешь:', true, 1, 39, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Да. Приятнее, когда звучит по-человечески', 3, 0, 0, 0, 0 from quiz_questions where text like 'Корабельный ИИ спрашивает%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Нет. Эмоции мешают точности отчётов', 0, 3, 0, 0, 1 from quiz_questions where text like 'Корабельный ИИ спрашивает%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Случайный режим. Каждый день — сюрприз', 0, 0, 0, 4, 2 from quiz_questions where text like 'Корабельный ИИ спрашивает%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Да, но только тёплые интонации в кризисах', 2, 0, 0, 0, 3 from quiz_questions where text like 'Корабельный ИИ спрашивает%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Перехватили послание: «Не прилетайте сюда». Остальные корабли уже летят. Ты:', true, 1, 40, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Добавляю в эфир: «Мы прилетим с миром, не бойтесь»', 3, 0, 0, 0, 0 from quiz_questions where text like 'Перехватили послание: «Не прилетайте%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Передаю в штаб. Решение не за мной — есть протокол', 0, 3, 0, 0, 1 from quiz_questions where text like 'Перехватили послание: «Не прилетайте%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Летим быстрее всех — разберёмся на месте', 0, 0, 0, 4, 2 from quiz_questions where text like 'Перехватили послание: «Не прилетайте%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Отвечаю: «Почему?» — жду разъяснений', 0, 2, 0, 1, 3 from quiz_questions where text like 'Перехватили послание: «Не прилетайте%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Погибшего пилота «восстановили» из клона с памятью до последнего бэкапа. Он не помнит последний год. Ты:', true, 1, 41, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Отношусь как к старому другу — помогаю вспомнить и влиться', 3, 0, 0, 0, 0 from quiz_questions where text like 'Погибшего пилота «восстановили»%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Это другой человек. Нужен новый контракт и проверка допусков', 0, 3, 0, 0, 1 from quiz_questions where text like 'Погибшего пилота «восстановили»%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Предлагаю ему самому решить: остаться «тем же» или начать с нуля', 0, 0, 0, 3, 2 from quiz_questions where text like 'Погибшего пилота «восстановили»%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Не могу принять. Прошу перевода в другой отсек', 0, 2, 0, 0, 3 from quiz_questions where text like 'Погибшего пилота «восстановили»%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Репликатор сломан: только «базовая каша» или «режим случайного вкуса». Ты:', true, 1, 42, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Каша. Добавлю мёд из запасов — будет нормально', 3, 0, 0, 0, 0 from quiz_questions where text like 'Репликатор сломан: только%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Каша. Предсказуемость важнее вкуса в полёте', 0, 3, 0, 0, 1 from quiz_questions where text like 'Репликатор сломан: только%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Случайный. Может выпасть что-то гениальное', 0, 0, 0, 4, 2 from quiz_questions where text like 'Репликатор сломан: только%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Случайный раз в день — для разнообразия', 1, 0, 0, 2, 3 from quiz_questions where text like 'Репликатор сломан: только%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('На старинной карте — отметка «здесь не бывать». Рядом с нашим маршрутом. Ты:', true, 1, 43, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Облетаю. Кто-то когда-то счёл это важным — уважаю', 2, 1, 0, 0, 0 from quiz_questions where text like 'На старинной карте — отметка%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Проверяю архивы. Если нет данных об угрозе — маршрут остаётся', 0, 3, 0, 0, 1 from quiz_questions where text like 'На старинной карте — отметка%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Летим туда. Надпись для того и есть, чтобы её проверить', 0, 0, 0, 4, 2 from quiz_questions where text like 'На старинной карте — отметка%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Собираю совет. Пусть экипаж решит', 2, 0, 0, 1, 3 from quiz_questions where text like 'На старинной карте — отметка%' and is_galaxy_watcher = false limit 1;

insert into quiz_questions (text, is_active, weight, sort_order, is_galaxy_watcher) values
('Перед миссией без возврата дают один кадр для родных. Ты записываешь:', true, 1, 44, false);
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Как мы все вместе за столом. И что я их люблю', 3, 0, 0, 0, 0 from quiz_questions where text like 'Перед миссией без возврата%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Чётко: что сделать с делами, пароли, инструкции', 0, 3, 0, 0, 1 from quiz_questions where text like 'Перед миссией без возврата%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Шутку. Пусть последнее, что увидят — смех', 0, 0, 0, 3, 2 from quiz_questions where text like 'Перед миссией без возврата%' and is_galaxy_watcher = false limit 1;
insert into quiz_answers (question_id, text, sweetness_delta, bitterness_delta, intensity_delta, extremeness_delta, sort_order)
select id, 'Тишину и вид из иллюминатора. Пусть почувствуют, где я был', 2, 0, 0, 1, 3 from quiz_questions where text like 'Перед миссией без возврата%' and is_galaxy_watcher = false limit 1;

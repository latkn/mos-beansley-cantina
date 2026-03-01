-- Вопросы рубрики «Смотрящий по галактике спрашивает»
-- Выполнить после schema.sql (и при необходимости после alter table quiz_questions add column is_galaxy_watcher)
-- При повторном запуске будут дубликаты — при необходимости удалить по is_galaxy_watcher = true или по тексту вопроса

-- 1. Два трона
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

-- 2. Десант
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

-- 3. Камера находок
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

-- 4. Сделка
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

-- 5. Приборы
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

-- 6. Столовая
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

-- 7. Пустыня астероидов
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

-- 8. Рычаг
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

-- 9. Баланда
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

-- 10. Спортзал
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

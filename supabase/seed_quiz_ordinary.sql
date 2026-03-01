-- Обычные вопросы для подбора напитка (космическая тематика)
-- Выполнить после schema.sql. При повторном запуске будут дубликаты — удалять по тексту вопроса при необходимости.
-- S = сладость, B = горечь, H = интенсивность, C = экстрим

-- 1. Режим посадки
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

-- 2. Космический бар
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

-- 3. Идеальная энергия
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

-- 4. Планета для посадки
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

-- 5. Гиперскачок
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

-- 6. Топливо для двигателя
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

-- 7. Прошивка личности
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

-- 8. Неизвестный плод
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

-- 9. Сбой системы
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

-- Ещё 15 обычных вопросов: космическая фантастика, 3 параметра (сладость, горечь, экспериментальность)
-- Сладость = мягкость, эмпатия, комфорт. Горечь = рациональность, жёсткость, прямота. Экспериментальность = риск, новизна.
-- intensity не используется (0). Выполнить после schema.sql и при необходимости после seed_quiz_ordinary.sql.

-- 1. Первый контакт
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

-- 2. Спасательная капсула
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

-- 3. Чужой артефакт
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

-- 4. Мятеж на корабле
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

-- 5. Чёрный ящик
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

-- 6. Инопланетный питомец
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

-- 7. Единственный скафандр
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

-- 8. Сны в анабиозе
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

-- 9. Голосование за курс
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

-- 10. Робот с эмоциями
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

-- 11. Чужое послание
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

-- 12. Клонированный член экипажа
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

-- 13. Еда из репликатора
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

-- 14. Тайна на карте
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

-- 15. Последнее сообщение домой
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

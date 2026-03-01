-- Инопланетные расы (по результатам «биометрии» — квиза) и задания для тамады

-- Таблица рас (4 расы из космической фантастики)
create table if not exists races (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  slug text unique not null,
  description text,
  sort_order int default 0,
  min_in_queue_for_alert int default 4,
  created_at timestamptz default now()
);

-- Ссылка у гостя на расу (определяется по квизу при регистрации)
alter table guests add column if not exists race_id uuid references races(id) on delete set null;
create index if not exists idx_guests_race on guests(race_id);

-- Задания для тамады (редактируемый список; при «объединить расу» выбирается задание)
create table if not exists tamada_tasks (
  id uuid primary key default uuid_generate_v4(),
  task_text text not null,
  race_id uuid references races(id) on delete set null,
  sort_order int default 0,
  is_active boolean default true,
  created_at timestamptz default now()
);

create index if not exists idx_tamada_tasks_active on tamada_tasks(is_active) where is_active = true;
create index if not exists idx_tamada_tasks_sort on tamada_tasks(sort_order);

-- Seed рас (один раз; при повторном запуске — по slug не дублируем)
insert into races (name, slug, description, sort_order, min_in_queue_for_alert)
values
  ('Ворлоки', 'vorloki', 'Раса из вавилонских секторов. По биометрии — тяга к сладкому и мягким вкусам.', 1, 4),
  ('Келдари', 'keldari', 'Пуристы тёмной материи. Высокая толерантность к горечи и чистоте протокола.', 2, 4),
  ('Зорги', 'zorg', 'Нейтринные экстремалы. Интенсивность и экспериментальность выше нормы.', 3, 4),
  ('Тау''ри', 'tauri', 'Гармонисты Кольца. Сбалансированный профиль по всем параметрам.', 4, 4)
on conflict (slug) do nothing;

-- Seed заданий для тамады (дурацкие задания; только если таблица пуста)
insert into tamada_tasks (task_text, sort_order, is_active)
select v.task_text, v.sort_order, v.is_active from (values
  ('Изобразить рождение сверхновой. Фотоотчёт обязателен.', 1, true),
  ('Синхронно пройтись как крабы от стойки до окна. Фотоотчёт обязателен.', 2, true),
  ('За 30 секунд придумать гимн своей расы и спеть хором. Фото/видеоотчёт.', 3, true),
  ('Выбрать лидера телепатией (молча, глазами). Фото лидера с подписью «Наш лидер».', 4, true),
  ('Станцевать как сломанные андроиды. Фотоотчёт обязателен.', 5, true),
  ('Воспроизвести звук чёрной дыры хором. Записать на видео.', 6, true),
  ('Построить пирамиду из тел (аккуратно). Фотоотчёт обязателен.', 7, true),
  ('Показать эволюцию вида за 60 секунд: от амёбы до гостя кантины. Видео.', 8, true),
  ('Сделать селфи в позе «мы только что узнали, что кофе готов». Фотоотчёт.', 9, true),
  ('Изобразить орбитальную станцию: все держат друг друга и крутятся. Фото.', 10, true),
  ('Придумать девиз расы и выкрикнуть его синхронно. Видеоотчёт.', 11, true),
  ('Показать «первый контакт» с другой расой в очереди (рукопожатие/ритуал). Фото.', 12, true)
) as v(task_text, sort_order, is_active)
where not exists (select 1 from tamada_tasks limit 1);

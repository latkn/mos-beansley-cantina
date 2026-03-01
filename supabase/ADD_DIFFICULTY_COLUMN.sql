-- Обязательно выполнить в Supabase: SQL Editor → New query → вставить → Run.
-- Устраняет ошибку: Could not find the 'difficulty' column of 'planet_tasks' in the schema cache

alter table planet_tasks
  add column if not exists difficulty int
  check (difficulty is null or (difficulty >= 1 and difficulty <= 5));

comment on column planet_tasks.difficulty is 'Сложность 1–5 для отображения цвета планеты; уровень экстрима 1–3 выводится из него.';

-- После выполнения обнови страницу приложения (или подожди несколько секунд — кэш схемы Supabase обновится).

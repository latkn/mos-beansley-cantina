-- Опциональная миграция: завершить все текущие активные планеты (старые задания).
-- Запускайте только если хотите начать с чистого листа после перехода на «три планеты по экстриму».
-- Данные не удаляются: планеты переходят в status = 'completed', остаются в отчётах.

update planet_tasks
set status = 'completed'
where planet_id in (select id from planets where status = 'active');

update planets
set status = 'completed', completed_at = coalesce(completed_at, now())
where status = 'active';

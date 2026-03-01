-- Время завершения задания (для отчётов: за какое время выполнено).
alter table planets add column if not exists completed_at timestamptz;
comment on column planets.completed_at is 'Когда задание планеты было завершено (с фото или отменой по коду штаба).';

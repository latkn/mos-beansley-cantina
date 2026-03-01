-- Заметка бариста о госте (видна только в интерфейсе бариста)
alter table guests add column if not exists barista_note text;

-- Сложность задания планеты (1–5): сохраняем при создании из tamada_tasks для отображения цветом.
alter table planet_tasks add column if not exists difficulty int check (difficulty is null or (difficulty >= 1 and difficulty <= 5));

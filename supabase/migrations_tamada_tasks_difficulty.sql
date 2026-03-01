-- Сложность задания (1–5): для подбора по «рейтингу» гостей (готовность к экспериментальным/острым напиткам).
-- 1 = лёгкое, 3 = среднее, 5 = сложное.
alter table tamada_tasks add column if not exists difficulty int default 3 check (difficulty >= 1 and difficulty <= 5);

comment on column tamada_tasks.difficulty is 'Сложность 1–5: чем выше — тем сложнее задание; подбор по профилю гостей (extremeness, intensity).';

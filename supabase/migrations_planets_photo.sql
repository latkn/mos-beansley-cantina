-- Фото для завершения задания планеты (режим тамады)
alter table planets add column if not exists photo_url text;

-- Bucket для фото: в Supabase Dashboard → Storage создать bucket "planet-photos", сделать public.
-- Либо: insert into storage.buckets (id, name, public) values ('planet-photos', 'planet-photos', true);

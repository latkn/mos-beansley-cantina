-- Bucket для фото напитков (кофейная карта).
-- 1) В Supabase Dashboard → Storage создать bucket "coffee-images", сделать public.
-- 2) Ниже — политики RLS, иначе загрузка даёт 400. Выполнить в SQL Editor.

-- Разрешить загрузку (INSERT) в бакет coffee-images для всех (anon ключ приложения)
create policy "Allow upload to coffee-images"
on storage.objects
for insert to public
with check (bucket_id = 'coffee-images');

-- Разрешить чтение (SELECT) для публичных URL картинок
create policy "Allow read coffee-images"
on storage.objects
for select to public
using (bucket_id = 'coffee-images');

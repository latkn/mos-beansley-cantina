-- Cosmic Registration System — Berlinman Edition
-- Run this in Supabase SQL Editor

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- guests
create table if not exists guests (
  id uuid primary key default uuid_generate_v4(),
  callsign text unique not null,
  avatar_url text,
  entropy int default 0,
  resonance int default 0,
  logic int default 0,
  total_score int default 0,
  planet_type text,
  clearance_level int default 1 check (clearance_level between 1 and 10),
  allergies jsonb default '[]',
  created_at timestamptz default now()
);

-- visits (history of calibrations)
create table if not exists visits (
  id uuid primary key default uuid_generate_v4(),
  guest_id uuid references guests(id) on delete cascade,
  entropy int,
  resonance int,
  logic int,
  total_score int,
  created_at timestamptz default now()
);

-- coffee_menu
create table if not exists coffee_menu (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  base_type text check (base_type in ('espresso', 'filter', 'cold_brew')),
  experimental_level int check (experimental_level between 1 and 10),
  is_shot boolean default false,
  is_short boolean default false,
  description text,
  ingredients jsonb default '[]',
  is_available boolean default true,
  prep_instructions text,
  sweetness int default 5 check (sweetness between 0 and 10),
  bitterness int default 5 check (bitterness between 0 and 10),
  intensity int default 5 check (intensity between 0 and 10),
  extremeness int default 5 check (extremeness between 0 and 10)
);

-- quiz_questions (вопросы для подбора напитка по 4 параметрам)
create table if not exists quiz_questions (
  id uuid primary key default uuid_generate_v4(),
  text text not null,
  is_active boolean default true,
  weight numeric(4,2) default 1 check (weight >= 0),
  sort_order int default 0,
  is_galaxy_watcher boolean default false,
  created_at timestamptz default now()
);

-- quiz_answers (ответы с влиянием на параметры: sweetness, bitterness, intensity, extremeness)
create table if not exists quiz_answers (
  id uuid primary key default uuid_generate_v4(),
  question_id uuid references quiz_questions(id) on delete cascade not null,
  text text not null,
  sweetness_delta int default 0 check (sweetness_delta between -3 and 3),
  bitterness_delta int default 0 check (bitterness_delta between -3 and 3),
  intensity_delta int default 0 check (intensity_delta between -3 and 3),
  extremeness_delta int default 0 check (extremeness_delta between -3 and 5),
  sort_order int default 0,
  created_at timestamptz default now()
);

create index if not exists idx_quiz_answers_question on quiz_answers(question_id);
create index if not exists idx_quiz_questions_active on quiz_questions(is_active) where is_active = true;

-- allergens (редактируемый список для опросника)
create table if not exists allergens (
  id uuid primary key default uuid_generate_v4(),
  label text not null,
  sort_order int default 0,
  created_at timestamptz default now()
);

create index if not exists idx_allergens_sort on allergens(sort_order);

-- planets (groups for show)
create table if not exists planets (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  status text default 'active' check (status in ('active', 'completed')),
  created_at timestamptz default now()
);

-- planet_members
create table if not exists planet_members (
  id uuid primary key default uuid_generate_v4(),
  planet_id uuid references planets(id) on delete cascade,
  guest_id uuid references guests(id) on delete cascade,
  unique(planet_id, guest_id)
);

-- planet_tasks
create table if not exists planet_tasks (
  id uuid primary key default uuid_generate_v4(),
  planet_id uuid references planets(id) on delete cascade,
  task_text text not null,
  status text default 'active' check (status in ('active', 'completed')),
  created_at timestamptz default now()
);

-- coffee_orders (очередь заказов для бариста)
create table if not exists coffee_orders (
  id uuid primary key default uuid_generate_v4(),
  guest_id uuid references guests(id) on delete cascade not null,
  coffee_id uuid references coffee_menu(id) on delete set null,
  coffee_name text not null,
  status text default 'pending' check (status in ('pending', 'ready', 'picked_up')),
  created_at timestamptz default now(),
  prepared_at timestamptz
);

-- RLS (optional: enable for production)
-- alter table guests enable row level security;
-- alter table visits enable row level security;
-- alter table coffee_menu enable row level security;
-- alter table planets enable row level security;
-- alter table planet_members enable row level security;
-- alter table planet_tasks enable row level security;

-- Realtime for board and barista (добавляем только если ещё не в публикации)
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'guests') then
    alter publication supabase_realtime add table guests;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'coffee_orders') then
    alter publication supabase_realtime add table coffee_orders;
  end if;
end $$;

-- Indexes
create index if not exists idx_guests_callsign on guests(callsign);
create index if not exists idx_guests_created_at on guests(created_at desc);
create index if not exists idx_visits_guest_id on visits(guest_id);
create index if not exists idx_coffee_experimental on coffee_menu(experimental_level);
create index if not exists idx_planets_status on planets(status);
create index if not exists idx_planet_members_planet on planet_members(planet_id);
create index if not exists idx_planet_members_guest on planet_members(guest_id);
create index if not exists idx_coffee_orders_status on coffee_orders(status);
create index if not exists idx_coffee_orders_created on coffee_orders(created_at asc);
create index if not exists idx_coffee_orders_guest on coffee_orders(guest_id);

-- Добавить колонки, если таблицы уже были созданы без них
alter table coffee_menu add column if not exists is_available boolean default true;
alter table coffee_menu add column if not exists prep_instructions text;
alter table guests add column if not exists allergies jsonb default '[]';
alter table guests add column if not exists sweetness int;
alter table guests add column if not exists bitterness int;
alter table guests add column if not exists intensity int;
alter table guests add column if not exists extremeness int;
alter table coffee_menu add column if not exists sweetness int default 5;
alter table coffee_menu add column if not exists bitterness int default 5;
alter table coffee_menu add column if not exists intensity int default 5;
alter table coffee_menu add column if not exists extremeness int default 5;
alter table coffee_menu add column if not exists image_url text;
alter table quiz_questions add column if not exists is_galaxy_watcher boolean default false;
create index if not exists idx_quiz_questions_galaxy_watcher on quiz_questions(is_galaxy_watcher) where is_galaxy_watcher = true and is_active = true;

-- Расширить статусы заказов для «выдан» (при ошибке «уже есть» — пропустить)
do $$
begin
  alter table coffee_orders drop constraint if exists coffee_orders_status_check;
  alter table coffee_orders add constraint coffee_orders_status_check check (status in ('pending', 'ready', 'picked_up'));
exception when duplicate_object then null;
end $$;

-- Seed coffee_menu (optional). Параметры: sweetness, bitterness, intensity, extremeness (0–10) по составу.
insert into coffee_menu (name, base_type, experimental_level, is_shot, is_short, description, sweetness, bitterness, intensity, extremeness) values
  ('Эспрессо', 'espresso', 1, true, true, 'Базовый протокол', 2, 7, 8, 2),
  ('Американо', 'espresso', 1, false, false, 'Разбавленный стандарт', 1, 6, 6, 1),
  ('Капучино', 'espresso', 2, false, false, 'Молочная матрица', 4, 4, 5, 2),
  ('Латте', 'espresso', 2, false, false, 'Мягкая калибровка', 5, 3, 4, 2),
  ('Флэт уайт', 'espresso', 3, false, true, 'Плотный слой', 4, 4, 6, 2),
  ('Фильтр', 'filter', 2, false, false, 'Чистый экстракт', 2, 5, 5, 3),
  ('Колд брю', 'cold_brew', 4, false, false, 'Холодная экстракция', 2, 5, 6, 5),
  ('Раф', 'espresso', 5, false, false, 'Сливки + ваниль', 6, 3, 4, 4),
  ('Аффогато', 'espresso', 6, true, true, 'Эспрессо + мороженое', 7, 3, 5, 5),
  ('Спешелти латте', 'espresso', 7, false, false, 'Сиропы и специи', 6, 3, 4, 7);

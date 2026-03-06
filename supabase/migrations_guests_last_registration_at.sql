-- Участник после выполнения задания не попадает в кружки/планеты, пока снова не пройдёт регистрацию.
-- last_registration_at обновляется при создании/обновлении гостя (регистрация).
alter table guests add column if not exists last_registration_at timestamptz default now();
comment on column guests.last_registration_at is 'Когда гость последний раз проходил регистрацию; после выполнения задания планеты снова участвует только если last_registration_at > completed_at планеты.';

-- Существующие гости считаются «зарегистрированными» на момент создания
update guests set last_registration_at = created_at where last_registration_at is null;

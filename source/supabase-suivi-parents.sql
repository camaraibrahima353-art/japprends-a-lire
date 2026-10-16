-- =====================================================================
-- J'APPRENDS À LIRE — Suivi des enfants par les parents (Supabase)
-- À coller une seule fois dans Supabase : SQL Editor → New query → Run.
-- Le script peut être relancé sans danger (il ne supprime aucune donnée).
-- =====================================================================

-- 1. Parents (un par compte Supabase Auth)
create table if not exists public.parents (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text,
  phone       text,
  created_at  timestamptz not null default now()
);

-- 2. Enfants créés par le parent
create table if not exists public.children (
  id          uuid primary key default gen_random_uuid(),
  parent_id   uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name        text not null check (char_length(name) between 1 and 40),
  avatar      text not null default '🦁',
  class_level text,
  created_at  timestamptz not null default now()
);
create index if not exists children_parent_idx on public.children(parent_id);

-- 3. Horaires de révision prévus (jour 1 = lundi … 7 = dimanche, heure locale)
create table if not exists public.schedules (
  id          uuid primary key default gen_random_uuid(),
  child_id    uuid not null references public.children(id) on delete cascade,
  weekday     smallint not null check (weekday between 1 and 7),
  start_time  time not null,
  end_time    time not null,
  created_at  timestamptz not null default now(),
  constraint schedules_time_ok check (end_time > start_time),
  constraint schedules_one_per_day unique (child_id, weekday)
);

-- 4. Séances d'apprentissage enregistrées par l'application de l'enfant
--    started_at = ouverture, ended_at = sortie de l'application (ou dernière activité)
create table if not exists public.sessions (
  id           uuid primary key,                       -- créé par l'application (envoi hors ligne possible)
  child_id     uuid not null references public.children(id) on delete cascade,
  started_at   timestamptz not null,
  ended_at     timestamptz not null,
  duration_sec integer not null default 0 check (duration_sec >= 0),
  exercises    integer not null default 0 check (exercises >= 0),
  correct      integer not null default 0 check (correct >= 0),
  activities   jsonb   not null default '{}'::jsonb,   -- secondes par activité : {"Maths": 420, "Dictée": 300}
  end_reason   text,                                   -- null = séance en cours
  device       text,
  updated_at   timestamptz not null default now(),
  constraint sessions_order check (ended_at >= started_at)
);
create index if not exists sessions_child_time_idx on public.sessions(child_id, started_at desc);

-- 5. Sécurité : chaque parent ne voit et ne modifie QUE ses enfants
alter table public.parents   enable row level security;
alter table public.children  enable row level security;
alter table public.schedules enable row level security;
alter table public.sessions  enable row level security;

drop policy if exists "parent: son profil" on public.parents;
create policy "parent: son profil" on public.parents
  for all to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "parent: ses enfants" on public.children;
create policy "parent: ses enfants" on public.children
  for all to authenticated using (parent_id = auth.uid()) with check (parent_id = auth.uid());

drop policy if exists "parent: horaires de ses enfants" on public.schedules;
create policy "parent: horaires de ses enfants" on public.schedules
  for all to authenticated
  using (exists (select 1 from public.children c where c.id = child_id and c.parent_id = auth.uid()))
  with check (exists (select 1 from public.children c where c.id = child_id and c.parent_id = auth.uid()));

drop policy if exists "parent: séances de ses enfants" on public.sessions;
create policy "parent: séances de ses enfants" on public.sessions
  for all to authenticated
  using (exists (select 1 from public.children c where c.id = child_id and c.parent_id = auth.uid()))
  with check (exists (select 1 from public.children c where c.id = child_id and c.parent_id = auth.uid()));

grant select, insert, update, delete on public.parents, public.children, public.schedules, public.sessions to authenticated;
revoke all on public.parents, public.children, public.schedules, public.sessions from anon;

-- 6. Création automatique de la fiche parent à l'inscription
create or replace function public.handle_new_parent()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.parents (id, full_name, phone)
  values (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'phone')
  on conflict (id) do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created_parent on auth.users;
create trigger on_auth_user_created_parent after insert on auth.users
  for each row execute function public.handle_new_parent();

-- 7. Date de mise à jour des séances
create or replace function public.touch_updated_at() returns trigger language plpgsql as $$
begin new.updated_at := now(); return new; end $$;
drop trigger if exists sessions_touch on public.sessions;
create trigger sessions_touch before update on public.sessions
  for each row execute function public.touch_updated_at();

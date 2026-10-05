-- J'APPRENDS À LIRE — schéma Supabase (synchronisation facultative)
-- Étape 1 (MVP) : une table "learners" reçoit les profils + leur progression (JSON),
-- envoyés depuis Administration → Données → « Envoyer la progression ».

create table if not exists public.learners (
  id          text primary key,              -- identifiant du profil créé sur l'appareil
  name        text not null,
  avatar      text,
  progress    jsonb not null default '{}',   -- niveaux, scores, étoiles, temps, erreurs, à revoir
  updated_at  timestamptz not null default now()
);

alter table public.learners enable row level security;

-- MVP : autorise l'envoi avec la clé anon. À durcir dès qu'on ajoute l'authentification
-- (ex. colonne owner uuid = auth.uid() et politiques par enseignant / parent).
create policy "anon upsert learners" on public.learners
  for insert to anon with check (true);
create policy "anon update learners" on public.learners
  for update to anon using (true) with check (true);
create policy "anon read learners" on public.learners
  for select to anon using (true);

-- Étape 2 (plateforme complète) : contenu pédagogique partagé et multi-langues.
create table if not exists public.content_packs (
  lang        text primary key,              -- 'fr', 'en', 'ff' (pular), 'man' (maninka), 'sus' (sosoxui)
  label       text not null,
  content     jsonb not null,                -- même format que CONTENT_PACKS.fr dans l'application
  updated_at  timestamptz not null default now()
);

create table if not exists public.attempts (   -- historique détaillé, pour statistiques enseignant
  id          bigint generated always as identity primary key,
  learner_id  text references public.learners(id) on delete cascade,
  item_key    text not null,                 -- ex. L:A, S:MA, W:MAMAN, T:A
  ok          boolean not null,
  level_id    text,
  created_at  timestamptz not null default now()
);
create index if not exists attempts_learner_idx on public.attempts(learner_id, created_at desc);

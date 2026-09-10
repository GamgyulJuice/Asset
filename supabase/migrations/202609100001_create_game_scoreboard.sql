-- Game Scoreboard schema
-- Run this file in Supabase Dashboard > SQL Editor. It does not require the CLI.

create extension if not exists pgcrypto;

create table if not exists public.players (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 1 and 20),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.game_scores (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references public.players(id) on delete cascade,
  score integer not null,
  played_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists game_scores_player_played_at_idx
  on public.game_scores (player_id, played_at asc);

-- Keeps the update timestamp server-side rather than trusting the browser.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists players_set_updated_at on public.players;
create trigger players_set_updated_at
before update on public.players
for each row execute function public.set_updated_at();

drop trigger if exists game_scores_set_updated_at on public.game_scores;
create trigger game_scores_set_updated_at
before update on public.game_scores
for each row execute function public.set_updated_at();

alter table public.players enable row level security;
alter table public.game_scores enable row level security;

-- This is a shared, public scoreboard: anyone holding the anon key can read and
-- manage entries. For private scoreboards, replace these with auth.uid()-based policies.
drop policy if exists "Public scoreboard can read players" on public.players;
create policy "Public scoreboard can read players"
  on public.players for select to anon using (true);
drop policy if exists "Public scoreboard can add players" on public.players;
create policy "Public scoreboard can add players"
  on public.players for insert to anon with check (true);
drop policy if exists "Public scoreboard can edit players" on public.players;
create policy "Public scoreboard can edit players"
  on public.players for update to anon using (true) with check (true);
drop policy if exists "Public scoreboard can delete players" on public.players;
create policy "Public scoreboard can delete players"
  on public.players for delete to anon using (true);

drop policy if exists "Public scoreboard can read scores" on public.game_scores;
create policy "Public scoreboard can read scores"
  on public.game_scores for select to anon using (true);
drop policy if exists "Public scoreboard can add scores" on public.game_scores;
create policy "Public scoreboard can add scores"
  on public.game_scores for insert to anon with check (true);
drop policy if exists "Public scoreboard can edit scores" on public.game_scores;
create policy "Public scoreboard can edit scores"
  on public.game_scores for update to anon using (true) with check (true);
drop policy if exists "Public scoreboard can delete scores" on public.game_scores;
create policy "Public scoreboard can delete scores"
  on public.game_scores for delete to anon using (true);

grant usage on schema public to anon;
grant select, insert, update, delete on public.players, public.game_scores to anon;

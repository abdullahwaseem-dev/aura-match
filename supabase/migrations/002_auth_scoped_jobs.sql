-- Migrates job_matches / applications from the anonymous device_id scoping
-- used before real authentication existed, to real per-user scoping tied to
-- Supabase Auth (auth.users), with RLS that Postgres actually enforces
-- (auth.uid() = user_id) instead of the previous permissive `using (true)`
-- policies.
--
-- Run this once in the Supabase SQL Editor (Dashboard -> SQL Editor -> New
-- query -> paste -> Run) for project fjpxajbctpwetfhahvlh.
--
-- Safe to run on a fresh/test project: this truncates job_matches and
-- applications first (device-id-scoped rows have no real owner to migrate
-- to), then changes their identity column. The `jobs` cache table itself is
-- untouched — job listings aren't user data.

begin;

-- 1. Drop the old permissive, device-id-scoped policies.
drop policy if exists "job_matches_read" on public.job_matches;
drop policy if exists "job_matches_write" on public.job_matches;
drop policy if exists "job_matches_update" on public.job_matches;
drop policy if exists "applications_read" on public.applications;
drop policy if exists "applications_write" on public.applications;
drop policy if exists "applications_update" on public.applications;

-- 2. Clear anonymous test data — these rows aren't tied to any real account.
truncate table public.applications, public.job_matches cascade;

-- 3. Swap device_id (self-reported text) for user_id (verified auth.uid()).
alter table public.job_matches drop constraint if exists job_matches_device_id_job_id_key;
alter table public.job_matches drop column if exists device_id;
alter table public.job_matches add column user_id uuid not null references auth.users(id) on delete cascade;
alter table public.job_matches add constraint job_matches_user_id_job_id_key unique (user_id, job_id);
drop index if exists job_matches_device_idx;
create index if not exists job_matches_user_idx on public.job_matches (user_id, match_score desc);

alter table public.applications drop constraint if exists applications_device_id_job_id_key;
alter table public.applications drop column if exists device_id;
alter table public.applications add column user_id uuid not null references auth.users(id) on delete cascade;
alter table public.applications add constraint applications_user_id_job_id_key unique (user_id, job_id);
drop index if exists applications_device_idx;
create index if not exists applications_user_idx on public.applications (user_id, updated_at desc);

-- 4. Real per-user RLS — Postgres enforces this natively from the caller's
-- verified JWT (auth.uid()), not from anything the client claims in the body.
create policy "job_matches_owner_select" on public.job_matches for select using (auth.uid() = user_id);
create policy "job_matches_owner_insert" on public.job_matches for insert with check (auth.uid() = user_id);
create policy "job_matches_owner_update" on public.job_matches for update using (auth.uid() = user_id);

create policy "applications_owner_select" on public.applications for select using (auth.uid() = user_id);
create policy "applications_owner_insert" on public.applications for insert with check (auth.uid() = user_id);
create policy "applications_owner_update" on public.applications for update using (auth.uid() = user_id);

commit;

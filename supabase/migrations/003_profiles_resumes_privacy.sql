-- Adds: per-user app settings (profiles, currently just the auto-draft
-- toggle), a Resume Library (saved resume snapshots), and DELETE policies
-- on job_matches/applications needed for the "delete my data" privacy
-- control (they only had select/insert/update before).
--
-- Run this once in the Supabase SQL Editor (Dashboard -> SQL Editor -> New
-- query -> paste -> Run) for project fjpxajbctpwetfhahvlh.

begin;

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  auto_draft_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
create policy "profiles_owner_select" on public.profiles for select using (auth.uid() = user_id);
create policy "profiles_owner_insert" on public.profiles for insert with check (auth.uid() = user_id);
create policy "profiles_owner_update" on public.profiles for update using (auth.uid() = user_id);

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

create table public.resumes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  file_name text not null,
  resume_text text not null,
  target_role text not null,
  ats_score int,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index resumes_user_idx on public.resumes (user_id, updated_at desc);

alter table public.resumes enable row level security;
create policy "resumes_owner_select" on public.resumes for select using (auth.uid() = user_id);
create policy "resumes_owner_insert" on public.resumes for insert with check (auth.uid() = user_id);
create policy "resumes_owner_update" on public.resumes for update using (auth.uid() = user_id);
create policy "resumes_owner_delete" on public.resumes for delete using (auth.uid() = user_id);

create trigger resumes_set_updated_at
  before update on public.resumes
  for each row execute function public.set_updated_at();

-- job_matches/applications (002_auth_scoped_jobs.sql) only got
-- select/insert/update policies — add delete so a user can actually erase
-- their own data via the Privacy Controls "delete my data" action.
create policy "job_matches_owner_delete" on public.job_matches for delete using (auth.uid() = user_id);
create policy "applications_owner_delete" on public.applications for delete using (auth.uid() = user_id);

commit;

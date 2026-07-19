-- Original Phase 2 (Jobs tab) schema — cached listings, AI match scores, and
-- the application tracker. Already applied to project fjpxajbctpwetfhahvlh;
-- committed here for documentation/reproducibility. See
-- 002_auth_scoped_jobs.sql for the follow-up migration to real per-user
-- auth (this version's device_id scoping predates authentication).

begin;

-- Cached external job listings, refreshed from free public job-board APIs.
create table public.jobs (
  id uuid primary key default gen_random_uuid(),
  source text not null default 'arbeitnow',
  external_id text not null,
  title text not null,
  company_name text not null,
  location text,
  remote boolean not null default false,
  description text not null,
  apply_url text not null,
  tags text[] not null default '{}',
  job_types text[] not null default '{}',
  posted_at timestamptz,
  fetched_at timestamptz not null default now(),
  unique (source, external_id)
);

create index jobs_fetched_at_idx on public.jobs (fetched_at desc);

-- AI-scored match per anonymous device identity (no auth system yet — the
-- app assigns a random uuid per install/browser and sends it as device_id).
create table public.job_matches (
  id uuid primary key default gen_random_uuid(),
  device_id text not null,
  job_id uuid not null references public.jobs(id) on delete cascade,
  match_score int not null check (match_score between 0 and 100),
  match_reasons text[] not null default '{}',
  target_role text,
  created_at timestamptz not null default now(),
  unique (device_id, job_id)
);

create index job_matches_device_idx on public.job_matches (device_id, match_score desc);

-- Consent-gated apply-assist pipeline: AI drafts tailored materials, the
-- user reviews and applies via the job's real posting themselves, then the
-- tracker records where each application stands.
create type public.application_status as enum ('saved', 'drafting', 'ready', 'applied', 'interviewing', 'offer', 'rejected');

create table public.applications (
  id uuid primary key default gen_random_uuid(),
  device_id text not null,
  job_id uuid not null references public.jobs(id) on delete cascade,
  status public.application_status not null default 'saved',
  tailored_resume text,
  cover_note text,
  applied_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (device_id, job_id)
);

create index applications_device_idx on public.applications (device_id, updated_at desc);

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger applications_set_updated_at
  before update on public.applications
  for each row execute function public.set_updated_at();

-- RLS: the backend authenticated to Supabase with the anon/publishable key
-- and there was no real user auth yet — device_id was a self-reported
-- client value, not a cryptographic identity. These policies were
-- intentionally permissive to match that trust model; 002_auth_scoped_jobs.sql
-- replaces them with real auth.uid()-scoped policies.
alter table public.jobs enable row level security;
alter table public.job_matches enable row level security;
alter table public.applications enable row level security;

create policy "jobs_public_read" on public.jobs for select using (true);
create policy "jobs_backend_write" on public.jobs for insert with check (true);
create policy "jobs_backend_update" on public.jobs for update using (true);

create policy "job_matches_read" on public.job_matches for select using (true);
create policy "job_matches_write" on public.job_matches for insert with check (true);
create policy "job_matches_update" on public.job_matches for update using (true);

create policy "applications_read" on public.applications for select using (true);
create policy "applications_write" on public.applications for insert with check (true);
create policy "applications_update" on public.applications for update using (true);

commit;

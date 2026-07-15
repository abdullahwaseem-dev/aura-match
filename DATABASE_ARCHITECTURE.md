# AURA MATCH — Database & API Infrastructure

The layer that makes the Flutter app (ARCHITECTURE.md) and the Python agent service (AGENT_ARCHITECTURE.md) share one source of truth.

---

## 1. How This Fits the Two Existing Documents

```
┌─────────────┐  JWT (Supabase Auth) ┌──────────────────┐        ┌────────────────────┐
│ Flutter App  │──────────────────────▶│ Node/Express      │───────▶│ Python Agent Service │
│ (supabase_   │◀──── Realtime ────────│ Gateway (server/) │        │ (LangGraph, new)     │
│  flutter)    │      (no polling)     └─────────┬────────┘        └──────────┬──────────┘
└──────┬───────┘                                 │                            │
       │  direct reads, RLS-secured              │  service_role key          │  service_role key
       ▼                                         ▼                            ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                              Supabase (one Postgres instance)                     │
│   auth.users · profiles · resumes · resume_versions · job_posts · job_matches     │
│   applications · interview_sessions · interview_logs · background_jobs           │
│   role_keywords · personas · persona_anchors  (from AGENT_ARCHITECTURE.md)        │
│   + pgvector extension + Row Level Security + Storage buckets + Realtime          │
└──────────────────────────────────────────────────────────────────────────────────┘
```

One correction to AGENT_ARCHITECTURE.md §3.1: that document specified generic "PostgreSQL + pgvector" with a plain `users` table. This document makes the provider concrete (Supabase) and adjusts the users table to Supabase's required pattern — `auth.users` (managed) + a linked `profiles` table (yours) — everything else in that document's schema (`role_keywords`, `personas`, `persona_anchors`) carries over unchanged into this same database.

---

## 2. Tech Stack Recommendation: Supabase

| Requirement | Supabase | Firebase | AWS (RDS + Cognito + Pinecone) | Neon + Clerk + Pinecone |
|---|---|---|---|---|
| Relational data | ✅ Postgres | ❌ Firestore is document/NoSQL — poor fit for Users→Resumes→Versions→Applications→Interviews joins | ✅ RDS Postgres | ✅ Postgres |
| Vector storage | ✅ `pgvector`, one extension, same DB | ❌ needs a bolted-on vector DB | ✅ but a separate service (Pinecone) | ✅ `pgvector` supported |
| Auth | ✅ built in, issues standard JWTs | ✅ built in | ✅ Cognito, separate service | Clerk, separate service |
| Row-level authorization | ✅ native RLS, enforced by Postgres itself | Rules-based, weaker relational guarantees | Hand-rolled in app code, or IAM policies | Hand-rolled — no RLS-to-JWT wiring out of the box |
| Realtime updates | ✅ built in, subscribes to Postgres changes | ✅ built in | Needs its own service (AppSync, or hand-rolled) | Needs its own service |
| File storage | ✅ built in, RLS-secured buckets | ✅ built in | S3, separate service | Separate service |
| Vendor count | **1** | 1 + a vector DB | 3–4 | 3 |

**Recommendation: Supabase.** The deciding factor isn't any single row — it's that every requirement in your prompt (relational + auth + vector) is one product, not three glued together, and that product is *Postgres*, which is the exact database AGENT_ARCHITECTURE.md already chose for the LangGraph checkpointer. That means one connection string serves the Flutter app, the Node gateway, and the Python agent service — one place to back up, one place to secure, one schema to reason about. Firebase is disqualified outright by the relational requirement — this domain is deeply relational (a resume has versions, a version has a score, a score feeds a match, a match becomes an application, an application spawns an interview session with per-turn logs); forcing that into documents fights the data model at every step. AWS and Neon+Clerk are both legitimate, more assembly-required alternatives — reach for AWS specifically if you later need infra a small team can't run themselves (dedicated compliance posture, multi-region active-active); until then, Supabase's integration is the leaner path.

---

## 3. Core Database Schema

### `profiles` (the `Users` table)

Supabase manages authentication identity in `auth.users` — you never add custom columns there. App-specific fields live in a linked `profiles` table, one row per user, created automatically on sign-up via a Postgres trigger.

```sql
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  plan text not null default 'free' check (plan in ('free', 'pro', 'unlimited')),
  auto_apply_enabled boolean not null default false,   -- the Privacy & Data master switch
  created_at timestamptz not null default now()
);

-- Auto-create a profile row the moment someone signs up
create function handle_new_user() returns trigger as $$
begin
  insert into public.profiles (id, email) values (new.id, new.email);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();
```

### `resumes` + `resume_versions` (version history)

Two tables, not one — `resumes` is the logical document lineage (you're building toward one target role), `resume_versions` is an append-only, immutable snapshot per iteration (the original upload, then each AI rebuild). Nothing is ever overwritten, so "show me what changed" is just a query, not a feature you have to build.

```sql
create table resumes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  target_role text not null,
  created_at timestamptz not null default now()
);

create table resume_versions (
  id uuid primary key default gen_random_uuid(),
  resume_id uuid not null references resumes(id) on delete cascade,
  version_number int not null,
  source text not null check (source in ('uploaded', 'ai_rebuilt')),
  raw_text text not null,
  file_path text,                        -- Supabase Storage object path for the original file
  ats_score int,
  matched_keywords text[] not null default '{}',
  missing_keywords text[] not null default '{}',
  embedding vector(1024),                -- see §4 for the embedding model
  created_at timestamptz not null default now(),
  unique (resume_id, version_number)
);
```

### `job_posts` + `job_matches` (the `Job_Matches` table)

Deliberately two tables, matching the product's real lifecycle from the design spec (Search Radar → Match Feed → Application Tracker): a **job post** is a raw crawled listing, shared by every user Aura might match it to. A **job match** is personal — one user's resume scored against one job post. An application only gets created once a match actually converts (§ below). Collapsing "match" and "application" into one row with a status column is the tempting shortcut and the wrong one — it conflates "Aura suggested this" with "the user (or Aura, with consent) acted on it," which are different events with different audit needs.

```sql
create table job_posts (
  id uuid primary key default gen_random_uuid(),
  source text not null,                  -- 'greenhouse' | 'lever' | 'workday' | 'search'
  external_id text,
  title text not null,
  company text not null,
  description text not null,
  location text,
  remote boolean not null default false,
  salary_min int,
  salary_max int,
  apply_url text not null,
  embedding vector(1024),
  fetched_at timestamptz not null default now(),
  unique (source, external_id)
);

create table job_matches (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  job_post_id uuid not null references job_posts(id) on delete cascade,
  resume_version_id uuid not null references resume_versions(id),
  fit_score int not null check (fit_score between 0 and 100),
  status text not null default 'suggested' check (status in ('suggested', 'dismissed', 'applied')),
  matched_at timestamptz not null default now(),
  unique (user_id, job_post_id)
);
```

### `applications`

```sql
create table applications (
  id uuid primary key default gen_random_uuid(),
  job_match_id uuid not null references job_matches(id),
  user_id uuid not null references auth.users(id) on delete cascade,
  submission_method text not null check (submission_method in ('ats_api', 'browser', 'manual_handoff')),
  status text not null default 'applied' check (status in ('applied', 'viewed', 'interview', 'offer', 'rejected')),
  applied_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

### `interview_sessions` + `interview_logs` (the `Interview_Logs` table)

Same reasoning as resumes: a session is the summary record (also the LangGraph `thread_id` this session's graph state is checkpointed under); each turn of the actual conversation is its own row, not one growing JSON blob, so individual turns can be indexed, queried, and RLS-checked uniformly.

```sql
create table interview_sessions (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null references applications(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  mode text not null check (mode in ('voice', 'text')),
  status text not null default 'in_progress' check (status in ('in_progress', 'completed', 'abandoned')),
  performance_report jsonb,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table interview_logs (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references interview_sessions(id) on delete cascade,
  turn_number int not null,
  speaker text not null check (speaker in ('aura', 'candidate')),
  content text not null,
  feedback jsonb,                        -- {structureScore, paceScore, note} — candidate turns only
  created_at timestamptz not null default now(),
  unique (session_id, turn_number)
);
```

**Audio is never stored here or anywhere server-side by default** — consistent with the privacy guardrail in the product plan. The voice pipeline (AGENT_ARCHITECTURE.md §7) transcribes in-stream and only the resulting text lands in `interview_logs`.

---

## 4. Vector Storage & AI Integration

### Embedding model

Use **Voyage AI** — Anthropic's own recommended embeddings partner, so the AI stack stays coherent (Claude for reasoning and generation, Voyage for embeddings) instead of pulling in a second unrelated vendor. Confirm the exact output dimension against Voyage's current model docs before finalizing the `vector(N)` column size — pin one model per column and don't mix embedding models within a column, since distances between vectors from different models aren't comparable.

### Where embeddings get written

| Table.column | Written when | Written by |
|---|---|---|
| `resume_versions.embedding` | Every time a resume is uploaded or rebuilt | Python agent service, inside the Resume/ATS graph (AGENT_ARCHITECTURE.md §4) |
| `job_posts.embedding` | Every time a job is crawled/ingested | Python agent service's sourcing pipeline (§5) |
| `role_keywords.embedding` | Once, when the keyword taxonomy is seeded (rarely changes) | A one-time seed script |

### Indexing for production scale

```sql
create extension if not exists vector;

create index on job_posts using hnsw (embedding vector_cosine_ops);
create index on role_keywords using hnsw (embedding vector_cosine_ops);
create index on resume_versions using hnsw (embedding vector_cosine_ops);
```

HNSW over IVFFlat — better recall at query time for this workload's scale, and it doesn't need a manual `lists` parameter re-tuned as the table grows.

### The two query patterns that actually run

**1. ATS keyword gap detection** — retrieve the relevant slice of the keyword taxonomy for the target role, ranked by relevance to what's actually in the resume, then hand that grounded list to the LLM (exactly the retrieval step in AGENT_ARCHITECTURE.md §4's graph):

```sql
select keyword, weight, 1 - (embedding <=> $1) as relevance
from role_keywords
where role_family = $2
order by embedding <=> $1
limit 40;
```

**2. Job fit pre-filtering** — a **retrieve-then-rank** pattern. Running the LLM fit-scorer against every open job post in the database would be slow and expensive; instead, vector search narrows thousands of postings down to the couple hundred that are plausibly relevant, and only that shortlist goes to the expensive LLM step:

```sql
select id, title, company, apply_url, 1 - (embedding <=> $1) as similarity
from job_posts
order by embedding <=> $1
limit 200;
```

The 200 results feed into the `score_fit` subgraph from AGENT_ARCHITECTURE.md §5 — vector search is the cheap net, the LLM is the precise hook.

---

## 5. API & Security

### Authentication

Supabase Auth issues short-lived JWTs on sign-in (email/password, or Sign in with Apple / Google — Sign in with Apple specifically is an App Store requirement once any other social login is offered). The Flutter app uses the official `supabase_flutter` package, which handles token storage, silent refresh, and session persistence across restarts — none of that is code your team writes by hand.

That same JWT is the credential everywhere: attached as a Bearer token on direct Supabase calls, and forwarded to the Node gateway and Python agent service, both of which verify it against Supabase's JWT secret before any handler runs.

### Two data-access paths — not everything goes through the gateway

| Path | Used for | Why |
|---|---|---|
| **Flutter → Supabase, direct** | Reading your own resumes, application tracker, interview history; simple writes like dismissing a match | RLS makes this safe — the database itself enforces "your rows only," so there's no reason to add gateway latency to a plain read |
| **Flutter → Node Gateway → Python Agent Service** | Uploading a resume for scanning, requesting a rebuild, hiring-manager scoring, starting an interview, authorizing an auto-apply | Anything that costs money, needs a secret vendor API key, or enforces a business rule (the 85% auto-apply threshold) must not be reachable directly from the client |

### Row Level Security — every user-owned table, the same shape

```sql
alter table resumes enable row level security;

create policy "select_own_resumes"
  on resumes for select
  using (auth.uid() = user_id);

create policy "insert_own_resumes"
  on resumes for insert
  with check (auth.uid() = user_id);

-- resume_versions has no user_id column directly — check through the parent
alter table resume_versions enable row level security;

create policy "select_own_resume_versions"
  on resume_versions for select
  using (
    exists (
      select 1 from resumes
      where resumes.id = resume_versions.resume_id
      and resumes.user_id = auth.uid()
    )
  );
```

Apply the same `select_own_*` / `insert_own_*` pattern to `job_matches`, `applications`, `interview_sessions`, `interview_logs`, and `background_jobs` (below) — every one of them has a `user_id` column specifically so this policy shape is uniform across the schema.

**One deliberate gap in these policies: no `update` policy on AI-derived columns, even for the row's owner.** A user can read their own `ats_score`; they cannot write it. Only the backend can — using the **`service_role` key**, which bypasses RLS entirely and must never reach the Flutter client. Treat it exactly like a root database password: it lives in the Node gateway's and Python agent service's server-side environment only, never in app config, never in a mobile build. The key the Flutter app holds is the `anon` key, which is safe to ship precisely because RLS is what actually enforces the boundary, not the key's secrecy.

### Triggering AI agents without the client timing out

A synchronous request that blocks on an LLM call for 5–30 seconds — or a browser-automation apply run for minutes — is a real reliability problem: mobile OSes background and kill long-held requests, load balancers time out around 30–60 seconds by default, and a frozen spinner with no feedback is a bad experience regardless. The fix is to never make the client wait on the work — **enqueue, don't block**:

```sql
create table background_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  job_type text not null check (job_type in ('resume_scan', 'resume_rebuild', 'hiring_manager_score', 'job_search_sweep')),
  status text not null default 'queued' check (status in ('queued', 'running', 'succeeded', 'failed')),
  result jsonb,
  error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

The flow:

1. Flutter calls `POST /api/resume/scan` on the Node gateway.
2. The gateway inserts a `background_jobs` row (`status = 'queued'`) and hands the work to the Python agent service — then responds `202 Accepted` with the `job_id` immediately. The HTTP request is over in milliseconds; the AI work keeps running independently.
3. The Python agent service updates that same row (`running` → `succeeded`, with `result` populated) as the LangGraph graph progresses.
4. Flutter never polls. It subscribes to that row via **Supabase Realtime** — the moment step 3 writes, the `ResumeBuilderViewModel` from ARCHITECTURE.md receives the update and transitions state, exactly like any other `notifyListeners()` call, just triggered by the database instead of a direct response.

For the one case that's a genuine live stream rather than a single result — the Interview Simulator's turn-by-turn conversation — use the WebSocket/SSE connection already specified in AGENT_ARCHITECTURE.md §7 instead of this job-row pattern; a live back-and-forth isn't a fire-and-forget job, and forcing it through the same shape would just be polling with extra steps.

This closes the loop across all three documents: a ViewModel method call becomes a gateway request, becomes a queued graph execution, becomes a database write, becomes a Realtime push, becomes a state transition back in the same ViewModel — no timeouts anywhere in that chain, because nothing in it is ever waiting synchronously on the AI.

---

## 6. Operational Notes

- **Connection pooling.** Both the Node gateway and the Python agent service should connect through Supabase's pooled connection string (port `6543`, Supavisor/PgBouncer), not the direct connection (port `5432`) — direct connections are a limited resource and a multi-instance deployment will exhaust them fast otherwise.
- **Backups.** Point-in-time recovery is a paid-tier feature — turn it on before real user data exists, not after an incident.
- **Migrations.** Manage schema changes through the Supabase CLI (`supabase migration new`, `supabase db push`) so every table in this document is version-controlled and reproducible, not click-created in a dashboard.

---

## 7. Build Sequence

Continues the phased rollout from the earlier documents:

| Step | What |
|---|---|
| 1 | Provision the Supabase project; run the schema above; enable `pgvector`; turn on RLS project-wide |
| 2 | Wire `supabase_flutter` into the app; replace the current placeholder auth with real sign-in |
| 3 | Point the Node gateway and Python agent service at the pooled connection string using the `service_role` key |
| 4 | Add `background_jobs` + Realtime to the Resume/ATS flow first — it's the most complete flow already, so it validates the whole async pattern before Job Search and Interview Prep are built on top of it |

I have direct access to Supabase's project tooling and can provision this for real — schema, RLS policies, and all — whenever you're ready to move from blueprint to a live project.

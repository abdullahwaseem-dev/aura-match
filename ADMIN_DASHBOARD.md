# AURA MATCH — Admin Dashboard & Operational Control Panel

The internal tool your team uses to run the business, watch AI spend in real time, and stay accountable for the sensitive data this platform holds.

---

## 0. Architecture Decision: A Separate Tool, Not a Fourth Consumer Screen

The admin panel is its own app, not a mode inside the Flutter app, and it doesn't borrow the Aurora design system. Different audience, different job: your team needs data density, fast filtering, and keyboard-driven workflows during an incident — not a glowing glass consumer aesthetic. Concretely:

- **Frontend:** a dedicated internal web app (React/Next.js + a data-grid component + a charting library suited to dense dashboards). Dark mode for the same reason ops tools usually default to it — long monitoring sessions — but utilitarian, table-first, not decorative.
- **Backend:** a protected `admin/*` router inside the **existing Node/Express gateway**, not a fourth service. This is deliberate — standing up a separate admin backend would be premature infrastructure for a lean team; a strictly auth-gated sub-router is enough, and it can be split out later if the ops surface genuinely outgrows it.
- **The admin backend, and only the admin backend, holds the Supabase `service_role` key.** The admin frontend never talks to Supabase directly, even with an "admin" JWT — every privileged action (suspend a user, adjust a cap, trigger a deletion) goes through a real endpoint with real business logic and a real audit log entry, not a raw table update. A "suspend" action should also revoke sessions and log a reason; a raw `UPDATE profiles SET status = 'suspended'` from the client can't guarantee that.

### Roles, not one shared "admin" flag

```sql
alter table profiles add column role text not null default 'user'
  check (role in ('user', 'support', 'analyst', 'admin', 'superadmin'));

create function is_admin(uid uuid) returns boolean as $$
  select exists (
    select 1 from profiles where id = uid and role in ('support', 'analyst', 'admin', 'superadmin')
  );
$$ language sql security definer stable;
```

| Role | Can see | Can do |
|---|---|---|
| `support` | User Management, that user's usage/history | Suspend/unsuspend, issue refunds, trigger privacy requests |
| `analyst` | Revenue Dashboard, AI Performance, Analytics & KPIs | Read-only — no account actions |
| `admin` | Everything above | All of the above, plus adjust caps, clear flags |
| `superadmin` | Everything | Role management, RLS audit, kill-switch controls |

**Every admin session requires MFA**, full stop — this isn't optional given what the panel can see. IP-allowlist or VPN-gate the admin panel in production once the team is a fixed set of people; loosen only if that becomes genuinely impractical.

---

## 1. Screens

### Revenue Dashboard

- **Top KPI row:** MRR, ARR (projected), New MRR this month, Churned MRR, Net Revenue Retention, active subscriptions by tier.
- **MRR trend chart:** stacked area chart by tier (Free doesn't contribute revenue but is worth showing alongside for context on funnel size).
- **Churn breakdown — the one that matters most for this product specifically:** a split chart of cancellation reason, distinguishing **"got hired" (good churn)** from **"dissatisfied" (bad churn)**. Treating all churn as equally bad is the wrong lens for a job-search product, per BUSINESS_PLAN.md's core pricing insight — this chart is what makes that insight actionable instead of just a paragraph in a planning doc.
- **Revenue by acquisition channel:** ties to the funnel in BUSINESS_PLAN.md §3 — which channel actually converts to paid, not just which one drives signups.
- **Top-up pack revenue:** tracked as its own line, separate from subscription MRR.
- **LTV:CAC tile**, with gross margin computed as revenue minus AI cost minus infra cost (pulls directly from the AI Performance screen below — these two dashboards should share numbers, not diverge).

### User Management

- **Main table:** searchable/filterable — email, plan tier, signup date, last active, lifetime revenue, current status (active / suspended / deletion-pending), open flags.
- **Per-user detail view:** profile info, subscription history, this-month usage vs. cap per action type (scans, rebuilds, applies, interview sessions), AI cost incurred this month, flag history, support ticket history.
- **Actions, every one logged:** suspend/unsuspend, refund, manually adjust plan or cap, trigger a privacy export/deletion, impersonate-for-support (time-boxed, banner-visible to the admin the whole time it's active, and logged start-to-finish).
- **Bulk actions require a typed confirmation and a reason field** — no silent bulk operations on user accounts, ever.

### AI Performance Monitoring

- **Cost per action type** (scan / rebuild / score / interview turn / auto-apply sweep) — the live version of the unit-economics table in BUSINESS_PLAN.md §2.1. This is where "were our estimates right" gets answered with real data.
- **Model usage breakdown:** call volume and cost split by Haiku / Sonnet / Opus — validates that the "cheap model for mechanical tasks, stronger model for reasoning" cost strategy is actually happening in production, not just in the plan.
- **Cache hit rate:** validates prompt caching is doing its job (target: high hit rate on system-prompt-heavy calls like scoring and scanning).
- **Latency and error rate per AI endpoint**, plus **refusal rate** (Claude declining a request) tracked separately from hard errors — a rising refusal rate on a specific action type is a signal worth investigating on its own, not just noise to retry past.
- **Auto-Apply submission method breakdown:** `ats_api` vs. `browser` vs. `manual_handoff`, as a trend line. This is specific to how AGENT_ARCHITECTURE.md designed the sourcing tiers — a rising `manual_handoff` share means either bot-detection is tightening industry-wide or your ATS-platform-API coverage needs to expand. Either way, it's the single most important operational health signal for that feature.
- **Top-N users by AI cost this month** — the whale list, feeding directly into §2's guardrails.

### The rest of the screen map (briefer — same underlying pattern as above)

| Screen | Purpose |
|---|---|
| Flagged Accounts | Queue of accounts tripped by the guardrails in §2, pending human review |
| Privacy Requests | GDPR/CCPA export and deletion requests, with SLA countdown |
| RLS Policy Audit | Automated check that every table that should have Row Level Security has it |
| Admin Audit Log | Every privileged action any admin has taken, searchable |

---

## 2. AI Token & Cost Guardrails

### The ledger every other guardrail reads from

```sql
create table ai_usage_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  action_type text not null check (action_type in
    ('resume_scan', 'resume_rebuild', 'hiring_manager_score', 'job_search_sweep', 'interview_turn', 'auto_apply')),
  model text not null,
  input_tokens int not null,
  output_tokens int not null,
  cost_estimate numeric(10, 6) not null,
  created_at timestamptz not null default now()
);
create index on ai_usage_events (user_id, created_at);
create index on ai_usage_events (action_type, created_at);

-- Fast rollups for dashboards, refreshed on a schedule — don't query the raw event
-- table for a chart that renders on every admin page load
create materialized view ai_usage_daily as
select user_id, action_type, date_trunc('day', created_at) as day,
       count(*) as call_count, sum(input_tokens) as total_input_tokens,
       sum(output_tokens) as total_output_tokens, sum(cost_estimate) as total_cost
from ai_usage_events
group by user_id, action_type, date_trunc('day', created_at);
```

This is the same instrumentation BUSINESS_PLAN.md recommended adding to `anthropicClient.js` — this document is where it earns its keep.

### Enforcement happens before the call, not after

The cap check has to run in the gateway/agent-service *before* Claude is invoked — an after-the-fact alert doesn't stop the spend, it just tells you about it once it's already happened.

```javascript
// server/src/middleware/aiUsageGuard.js
async function aiUsageGuard(req, res, next) {
  const { userId, actionType, plan } = req.aiContext;

  const usage = await getUsageThisPeriod(userId, actionType);
  const cap = getCapForTier(plan, actionType);           // from the BUSINESS_PLAN.md tier table
  if (usage.count >= cap) {
    return res.status(402).json({ error: 'monthly_cap_reached', upgradeUrl: '/pricing' });
  }

  const recentCalls = await getRecentVelocity(userId, actionType, '10 minutes');
  if (recentCalls > VELOCITY_THRESHOLD[actionType]) {
    await flagAccount(userId, 'velocity_anomaly', 'throttle');
    return res.status(429).json({ error: 'rate_limited', retryAfterSeconds: 60 });
  }

  next();
}
```

Two separate checks, deliberately: the **monthly cap** enforces the pricing model; the **velocity check** catches something a monthly cap misses entirely — a free-tier account running 200 scans in an hour isn't a heavy legitimate user, it's a script, and it'll blow past a monthly limit slowly enough to look normal if that's the only check in place.

### Escalation ladder — never straight to "block"

| Level | Trigger | Action | Human involved? |
|---|---|---|---|
| 1 — Warn | Approaching monthly cap (80%) | In-app notice, no restriction yet | No |
| 2 — Throttle | Velocity threshold tripped | Rate-limited (429 + cooldown), account flagged for review | No, but queued for one |
| 3 — Suspend pending review | Repeated velocity trips, or single-session cost anomaly (e.g. one session over $5) | Account paused, not deleted; appears in Flagged Accounts | Reviewed within a set SLA (e.g. 24h) |
| 4 — Permanent action | Confirmed abuse after review | Ban | **Always requires a human admin to confirm** — never fully automatic |

That last rule matters: an automated system will produce false positives on real power users, and a platform whose entire pitch is trustworthiness can't let an automated ban be the first a legitimate paying user hears about a problem.

### Platform-wide circuit breaker

A daily AI-spend ceiling for the whole platform, with **graduated degradation, not an outage**, if it's approached: pause the least-critical, most-expensive load first (new job-search sweeps) while keeping the core value prop (ATS scanning) running. An all-or-nothing kill switch protects the budget by breaking the product; a graduated one protects the budget while protecting the reason anyone's paying for it.

---

## 3. Data Privacy & Security Compliance

### Right to be Forgotten — the actual technical flow

```sql
create table privacy_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  request_type text not null check (request_type in ('export', 'deletion')),
  status text not null default 'pending' check (status in ('pending', 'processing', 'completed', 'failed')),
  requested_at timestamptz not null default now(),
  sla_due_at timestamptz not null default (now() + interval '72 hours'),
  completed_at timestamptz,
  handled_by uuid references auth.users(id)
);
```

**72-hour internal SLA** — comfortably inside GDPR's "without undue delay" standard, and a concrete, trustworthy promise for a platform holding people's resumes and work history.

**Hard-delete PII; anonymize, don't delete, aggregate usage records.** When a deletion request completes, `resumes`, `resume_versions` (including the Storage bucket file), `job_matches`, `applications`, `interview_sessions`, and `interview_logs` are actually removed — cascading deletes handle this cleanly given the schema's foreign keys. `ai_usage_events` rows for that user are **not** deleted — they're stripped of the `user_id` link and retained in anonymized form, because aggregate financial and usage history has a legitimate business/accounting retention need, and anonymized data isn't personal data under GDPR anymore. This is the correct distinction to build in, not a shortcut.

### RLS Policy Audit — the automated check for the most common Supabase mistake

The single most common way a Supabase project leaks data isn't a broken policy — it's a **new table someone forgot to enable RLS on.** This should be a scheduled query, not a manual checklist:

```sql
select schemaname, tablename, rowsecurity as rls_enabled
from pg_tables
where schemaname = 'public'
order by rls_enabled asc;   -- anything false surfaces at the top
```

Run this on a schedule and alert if any user-data table shows `rls_enabled = false`. This is cheap to build and catches a real, easy-to-make mistake before it becomes an incident.

### Every privileged access, logged — no exceptions

```sql
create table admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references auth.users(id),
  action text not null,                     -- 'viewed_resume' | 'exported_data' | 'suspended_account' | 'adjusted_cap' | ...
  target_user_id uuid references auth.users(id),
  reason text,
  metadata jsonb,
  created_at timestamptz not null default now()
);
```

Every time an admin opens a user's resume, exports data, or takes an account action, it's logged — this is what makes "who looked at this person's data, and why" answerable, which matters both for compliance and for your own team's internal trust.

### Two more pieces, already decided elsewhere — confirmed consistent here

- **Voice recordings are never stored server-side** (AGENT_ARCHITECTURE.md §7) — so there is deliberately no "listen to recordings" admin feature. Nothing to build, nothing to secure, nothing to leak.
- **Consent is timestamped and admin-visible** — `auto_apply_enabled` and any marketing opt-in on `profiles` should carry a `_set_at` timestamp, so "prove this user consented to auto-apply on this date" is a lookup, not an investigation.

---

## 4. Analytics & KPIs

**North Star metric: Verified ATS Score Improvement** (average scan-to-rebuild score delta, across all users, this period). Revenue metrics tell you if the business is healthy; this one tells you if the product actually works — and it should sit at the very top of the dashboard, above MRR, because a platform that stops improving people's real outcomes will lose the business metrics eventually anyway.

| Category | Metrics |
|---|---|
| **Revenue** | MRR, ARR, ARPU, LTV, CAC, LTV:CAC, free-to-paid conversion rate, tier distribution, top-up attach rate, gross margin (revenue − AI cost − infra cost) |
| **Retention & Engagement** | DAU/MAU, cohort retention curves, good-churn vs. bad-churn split, time-to-first-scan (activation speed), drop-off through the scan → rebuild → hiring-manager → apply → interview funnel |
| **Product / AI Effectiveness** | Verified ATS score improvement (North Star), application-to-interview conversion rate, interview simulator completion rate, cost per resume / per application / per interview session, auto-apply suggest-vs-apply-vs-dismiss ratio |
| **Trust & Safety** | Flagged accounts this period, false-positive rate on flags (flagged then cleared — a fairness metric worth tracking on purpose), manual-handoff rate on Auto-Apply, privacy-request SLA compliance rate |

---

Ready to start on whichever piece unblocks the team fastest — the `ai_usage_events` ledger and pre-call guardrail middleware are the highest-leverage first build, since every other screen in this document reads from that same data.

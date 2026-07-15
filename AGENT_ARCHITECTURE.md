# AURA MATCH — Multi-Agent AI Architecture

How Aura's four AI systems are actually built: the framework, the graphs, the prompts, and the database underneath them.

---

## 1. Architecture at a Glance

```
                    ┌─────────────────────┐
   Flutter App  ───▶│  Node/Express        │   auth, REST/WebSocket contracts,
  (iOS/Android/     │  Gateway (existing)   │   file upload, simple structured
   Mac/Web)         │  — server/            │   Claude calls (unchanged)
                    └──────────┬───────────┘
                               │ internal API (REST + SSE/WebSocket)
                               ▼
                    ┌─────────────────────┐
                    │  Python Agent Service │   LangGraph graphs for every
                    │  — agent-service/      │   stateful, multi-step, or
                    │  (new)                 │   human-gated AI workflow
                    └──────────┬───────────┘
                               │
        ┌──────────────┬──────┴───────┬──────────────────┐
        ▼              ▼              ▼                  ▼
   Claude API     PostgreSQL      ATS platform       Playwright
  (reasoning,     + pgvector      APIs (Greenhouse,   (browser
   scoring,       (app data +     Lever, Workday…)    fallback for
   generation)    embeddings +    + Claude web_search  application
                  LangGraph        (job discovery)      forms)
                  checkpoints)
```

**Two backend services, not one, and not four.** The Node gateway you already have keeps doing what it does well — auth, the Flutter-facing contract, and the resume/hiring-manager calls that are simple structured extraction, not autonomous agents. A new Python service takes on the two workflows that are genuinely agentic: **Auto-Apply** (multi-step, needs browser automation, needs to pause for human consent) and **Interview Simulator** (long-running, stateful, resumable conversations). This is a deliberate split, not framework sprawl — the reasoning is in §2.

---

## 2. The Framework Decision: LangGraph, Not CrewAI

| | **CrewAI** | **LangGraph** |
|---|---|---|
| Mental model | Agents with roles/goals negotiate a plan among themselves | You define the exact graph — nodes and edges — the state can take |
| Best for | Open-ended tasks where the path isn't known ahead of time (research, brainstorming) | Workflows where the path *is* known, and getting a step wrong has consequences |
| Determinism | Low — the crew decides its own sequencing | High — you decide the sequencing; the LLM decides *within* a node |
| Persistence / resumability | Bolted on, inconsistent across versions | Core primitive — a `checkpointer` persists full graph state after every step |
| Human-in-the-loop | Possible, but not a first-class primitive | `interrupt()` is a first-class primitive — a graph can pause mid-run and wait for a real person |
| Multi-language support | Python only | Python (most mature) and JS/TS (`@langchain/langgraph`, production-ready) |

**Recommendation: LangGraph.** Here's why it's not close, for this specific product:

- **The Auto-Apply consent gate is a hard requirement, not a nice-to-have.** A borderline-fit job (60–84%) must stop and wait for the user to say yes before Aura submits anything on their behalf — see §5. That's `interrupt()` in one line in LangGraph. In CrewAI, you'd be building that pause-and-resume machinery yourself.
- **Job search runs for days; interview sessions get backgrounded and resumed.** Both need state that survives a server restart. LangGraph's checkpointer does this by default, against Postgres — the same database everything else already uses (§3).
- **Auditable scoring.** When Aura tells a user "you're in the top 18% for this persona," that number has to come from a repeatable, inspectable process — not from however a crew of agents happened to negotiate it that run. A graph's nodes are inspectable and independently testable; a crew's internal negotiation is not.

CrewAI is a good tool — for a different kind of product. A platform where "figure out the plan" is the hard part (open research agents, autonomous coding agents) benefits from letting agents negotiate. A platform where "never submit an application without consent" is the hard part needs a framework built around control, not delegation.

### Why a separate Python service, not `@langchain/langgraph` inside the existing Node app

LangGraph JS is genuinely production-ready, and if Auto-Apply were pure API integration, staying in one language would win. It isn't: filling out an arbitrary company's application form when no ATS-platform API exists means real browser automation, and that ecosystem — Playwright's Python bindings, the anti-bot-evasion literature, the scraping tooling — is deeper and better-documented in Python. Splitting the service also means the Node gateway (latency-sensitive, talks to the Flutter app directly) never shares a process with a job that might be mid-way through driving a headless browser through a ten-step application form. Scale and deploy them independently.

---

## 3. Shared Foundations

All four systems sit on the same three pieces of infrastructure. Build these once.

### 3.1 — Database: PostgreSQL + pgvector

One database, three jobs: application data, vector search, and LangGraph's own session state. No separate vector database needed at this scale — `pgvector` is a Postgres extension, so it's one thing to run, back up, and reason about.

```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  plan TEXT NOT NULL DEFAULT 'free',
  auto_apply_enabled BOOLEAN NOT NULL DEFAULT false,   -- the Privacy & Data master switch
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE resumes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  version INT NOT NULL,
  target_role TEXT NOT NULL,
  raw_text TEXT NOT NULL,
  rebuilt_text TEXT,
  ats_score INT,
  embedding VECTOR(1536),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- The curated "what good looks like" reference set — grounds the ATS engine
-- so it scores against real taxonomy, not whatever the model free-associates.
CREATE TABLE role_keywords (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_family TEXT NOT NULL,          -- e.g. 'product_management'
  keyword TEXT NOT NULL,
  weight REAL NOT NULL DEFAULT 1.0,
  embedding VECTOR(1536),
  UNIQUE (role_family, keyword)
);

CREATE TABLE personas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  label TEXT NOT NULL,                -- 'SaaS, Series B, US'
  region TEXT NOT NULL,
  rubric JSONB NOT NULL               -- category weights + tone instructions, see §6
);

-- Few-shot calibration anchors — see §6. This is what makes persona
-- scoring consistent run to run instead of drifting.
CREATE TABLE persona_anchors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  persona_id UUID NOT NULL REFERENCES personas(id),
  resume_excerpt TEXT NOT NULL,
  reference_score INT NOT NULL,
  embedding VECTOR(1536)
);

CREATE TABLE job_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source TEXT NOT NULL,               -- 'greenhouse' | 'lever' | 'workday' | 'search'
  external_id TEXT,
  title TEXT NOT NULL,
  company TEXT NOT NULL,
  description TEXT NOT NULL,
  location TEXT,
  remote BOOLEAN NOT NULL DEFAULT false,
  apply_url TEXT NOT NULL,
  embedding VECTOR(1536),
  fetched_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  job_post_id UUID NOT NULL REFERENCES job_posts(id),
  resume_id UUID NOT NULL REFERENCES resumes(id),
  fit_score INT NOT NULL,
  status TEXT NOT NULL DEFAULT 'not_applied',
  submission_method TEXT,             -- 'ats_api' | 'browser' | 'manual_handoff'
  applied_at TIMESTAMPTZ
);

CREATE TABLE interview_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID NOT NULL REFERENCES applications(id),
  mode TEXT NOT NULL,                 -- 'voice' | 'text'
  transcript JSONB NOT NULL DEFAULT '[]',
  performance_report JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- LangGraph's checkpointer creates and manages its own tables here automatically
-- (via PostgresSaver.setup()) — same database, separate tables, zero extra ops.
```

`pgvector` earns its place three separate times in this schema: matching resume content against `role_keywords` (§4), retrieving calibration anchors for consistent persona scoring (§6), and semantic-matching resumes against `job_posts` for fit scoring (§5).

### 3.2 — LangGraph state and checkpointing

Every graph in this document shares the same shape: a typed `State`, a set of nodes (plain functions), edges (including conditional ones), and a Postgres-backed checkpointer so the graph can be paused — by a human, a dropped connection, or a multi-day wait for the next crawl cycle — and resumed exactly where it left off.

```python
from langgraph.checkpoint.postgres import PostgresSaver

checkpointer = PostgresSaver.from_conn_string(POSTGRES_URL)
checkpointer.setup()  # idempotent — creates LangGraph's tables on first run

graph = builder.compile(checkpointer=checkpointer)

# Every invocation is scoped to a thread_id — resume a user's session by reusing it.
result = graph.invoke(input, config={"configurable": {"thread_id": session_id}})
```

### 3.3 — The persona-config pattern

Hiring Manager Mode and the Interview Simulator both "act as someone" — but they build that someone differently, so this is a pattern, not a shared class. Hiring Manager personas are **fixed and pre-calibrated** (§6): a small library of region/industry rubrics the user picks from. Interview personas are **assembled per session** from the specific job posting and resume in play (§7). Both ultimately produce the same shape — a rubric plus tone instructions — which is what makes them safe to swap into the same prompt template.

---

## 4. Resume & ATS Engine

**What it needs to do:** read an uploaded PDF, find weak or missing keywords, generate a new ATS-safe resume.

The Node gateway already does file extraction (`pdf-parse` / `mammoth`) — that stays exactly as it is; it's deterministic text extraction, not an AI task, and doesn't belong in an agent graph. Everything downstream of "I now have resume text" moves into a LangGraph graph in the Python service.

**The key design decision: ground the keyword gap analysis in retrieved data, not a free-floating LLM judgment.** Asking Claude to both invent the "correct" keyword set for a role *and* judge the resume against it in the same breath means the bar moves every run. Instead, retrieve a curated keyword taxonomy first, then have the model reason over real, retrieved data.

```
┌──────────────┐   ┌──────────────────┐   ┌───────────────────┐   ┌─────────────┐
│ parse_document│──▶│ retrieve_keywords │──▶│ ats_simulation_llm │──▶│ (conditional)│
└──────────────┘   │ (pgvector query)   │   │ (Claude, grounded  │   └──────┬──────┘
                    └──────────────────┘   │  in retrieval)     │          │
                                            └───────────────────┘   score < 80 OR
                                                                     gaps found
                                                                            │
                                                                            ▼
                                                              ┌────────────────────┐
                                                              │ ask_clarifying_qs   │──▶ interrupt()
                                                              │ (waits for the user)│    (app renders
                                                              └──────────┬──────────┘     the Q&A chat)
                                                                         ▼
                                                              ┌────────────────────┐
                                                              │ rebuild_resume_llm  │
                                                              └──────────┬──────────┘
                                                                         ▼
                                                              ┌────────────────────┐
                                                              │ persist_version     │
                                                              └────────────────────┘
```

```python
class ResumeState(TypedDict):
    raw_text: str
    target_role: str
    retrieved_keywords: list[dict]   # [{keyword, weight}, ...] from pgvector
    scan_result: dict | None
    qa_answers: list[dict]
    rebuilt_text: str | None

def retrieve_keywords(state: ResumeState) -> ResumeState:
    role_embedding = embed(state["target_role"])
    rows = db.query("""
        SELECT keyword, weight FROM role_keywords
        WHERE role_family = ats_role_family(%s)
        ORDER BY embedding <=> %s LIMIT 40
    """, [state["target_role"], role_embedding])
    return {**state, "retrieved_keywords": rows}

def ats_simulation_llm(state: ResumeState) -> ResumeState:
    result = claude.messages.create(
        model="claude-opus-4-8",
        system=ATS_SYSTEM_PROMPT,
        messages=[{"role": "user", "content": build_scan_prompt(state)}],
        output_config={"format": {"type": "json_schema", "schema": SCAN_SCHEMA}},
    )
    return {**state, "scan_result": json.loads(result.content[0].text)}

def needs_clarification(state: ResumeState) -> str:
    return "ask_clarifying_qs" if state["scan_result"]["atsScore"] < 80 else "persist_version"

builder = StateGraph(ResumeState)
builder.add_node("parse_document", parse_document)         # wraps the existing Node extraction call
builder.add_node("retrieve_keywords", retrieve_keywords)
builder.add_node("ats_simulation_llm", ats_simulation_llm)
builder.add_node("ask_clarifying_qs", ask_clarifying_qs)    # calls interrupt()
builder.add_node("rebuild_resume_llm", rebuild_resume_llm)
builder.add_node("persist_version", persist_version)

builder.add_edge("parse_document", "retrieve_keywords")
builder.add_edge("retrieve_keywords", "ats_simulation_llm")
builder.add_conditional_edges("ats_simulation_llm", needs_clarification)
builder.add_edge("ask_clarifying_qs", "rebuild_resume_llm")
builder.add_edge("rebuild_resume_llm", "persist_version")
```

**The prompt itself** is deliberately told to treat the retrieval as ground truth, not a suggestion:

```
SYSTEM:
You are Aura's ATS-simulation engine. You will be given a candidate's resume,
their target role, and a retrieved list of canonical keywords for that role
family, each with an importance weight — pulled from Aura's own keyword
taxonomy, not your own judgment.

Score "missing keywords" and "matched keywords" using ONLY the retrieved list
as ground truth. Do not invent keywords outside it. Your qualitative judgment
is for tone, phrasing, and prioritization — not for deciding what the keyword
set is.
```

This is the same `/api/resume/scan` contract the Flutter app already calls — the endpoint shape doesn't change, only what's running behind it.

---

## 5. The Auto-Apply Agent

**What it needs to do:** search the web for jobs, and fill out application forms — safely, without getting blocked, and never without the user's consent on anything borderline.

The single most important insight here: **most "company career pages" aren't bespoke.** A large share of real job postings are served by a handful of ATS platforms — Greenhouse, Lever, Workday, iCIMS — each with a stable, documented (or stably reverse-engineered) submission format. That means the safe path isn't "drive a browser and hope" for every application; it's "identify the platform, use its structured path, and only fall back to browser automation when there genuinely is no other option."

### Sourcing tier 1 — structured, no risk of being blocked

Query each ATS platform's own public job API directly (Greenhouse's Job Board API, Lever's Postings API, etc.). This is the primary source: fast, reliable, produces clean structured `JobPost` rows, and carries zero "scraping" risk because it's the platform's own intended integration surface.

### Sourcing tier 2 — discovery for everything else

For roles not on a known ATS platform, use Claude's server-side `web_search` tool to discover postings on company career pages directly. This is discovery only — reading a public page to find a listing, the same thing a search engine does. It is **not** used for submission.

### Fit scoring — reuses the Hiring Manager subgraph

```
┌─────────────┐   ┌──────────────┐   ┌───────────────┐   ┌─────────────────────┐
│ search_jobs  │──▶│ score_fit     │──▶│ (conditional)  │──▶│ resolve_ats_platform │
│ (tier 1 + 2) │   │ [reused       │   └───────┬───────┘   └──────────┬──────────┘
└─────────────┘   │  subgraph]    │           │                      │
                   └──────────────┘    fit ≥ 85 & consent      known platform?
                                        enabled → auto              │
                                        60–84 → interrupt()   ┌─────┴─────┐
                                        < 60 → discard        ▼           ▼
                                                        submit_via_api  submit_via_browser
                                                                            │
                                                                     CAPTCHA / bot-check
                                                                     detected? ──▶ flag_for_manual_review
```

`score_fit` is not a new implementation — it's the same scoring logic as Hiring Manager Mode (§6), invoked as a **LangGraph subgraph**, so "how good is this resume, really" is computed identically everywhere it matters instead of drifting between two code paths.

```python
def route_on_fit(state: ApplyState) -> str:
    if state["fit_score"] >= 85 and state["user_auto_apply_enabled"]:
        return "resolve_ats_platform"
    if state["fit_score"] >= 60:
        return "await_consent"           # interrupt() — Auto-Apply Consent screen
    return "discard"

builder.add_node("score_fit", hiring_manager_subgraph)     # reused, not reimplemented
builder.add_conditional_edges("score_fit", route_on_fit)
builder.add_node("await_consent", await_consent)           # calls interrupt()
```

### Submission — and the hard line on CAPTCHAs

For a known ATS platform, submit through its structured application endpoint using the user's own resume and answers — this is assistive automation on the user's own authorized submission, the same category of action as a password manager auto-filling a form the user asked it to fill.

For everything else, a Playwright-driven generic form-filler is the fallback — with one non-negotiable rule: **if a form presents a CAPTCHA or an explicit bot-check, the agent stops.** It does not attempt to solve or route around it. That barrier exists specifically to block automated submission, and defeating it isn't something this system does, on this or any other site. The graph routes to `flag_for_manual_review` instead, and the application surfaces in the Flutter Application Tracker as "Aura drafted this — finish it yourself," which is exactly the "Review first" path already designed into the Match Feed screen.

Everything sits inside per-domain rate limits and the daily-send cap and per-company allow-list from the original product plan — those guardrails don't move to the agent layer, they gate it.

---

## 6. Hiring Manager Mode — Giving the AI a Persona

**What it needs to do:** score a resume the way a real hiring manager in a specific region/industry would, consistently.

A system prompt alone ("you are a hiring manager in SaaS") is not a persona — it's a mood. Two runs against the identical resume can land 15 points apart. The fix is **retrieval-augmented calibration**: pair each persona with a handful of real, pre-scored resume excerpts stored as anchors, retrieved and shown to the model as few-shot examples every time that persona scores something.

```python
class Persona(TypedDict):
    label: str            # 'SaaS, Series B, US'
    region: str
    rubric: dict           # {"Impact": 0.3, "Clarity": 0.2, "Keyword Match": 0.3, "Formatting": 0.2}

def build_scoring_prompt(resume_text: str, persona: Persona, anchors: list[dict]) -> str:
    anchor_block = "\n\n".join(
        f"Reference resume (scored {a['reference_score']}/100 by a real {persona['label']} manager):\n{a['resume_excerpt']}"
        for a in anchors
    )
    return f"""
Persona: {persona['label']} ({persona['region']})
Rubric weights: {json.dumps(persona['rubric'])}

Calibration references — score this resume relative to these, not in a vacuum:
{anchor_block}

Resume to score:
{resume_text}
"""
```

The anchors are retrieved from `persona_anchors` via `pgvector` similarity to the resume being scored — so the model is always calibrated against the *most relevant* reference points, not a fixed generic set. This is what makes "top 18% for this persona" a claim the team can actually stand behind instead of a number the model made up to sound confident.

---

## 7. Interview Simulator — Realistic Voice and Text Interviews

**What it needs to do:** conduct a real interview, adapt follow-ups to what the candidate actually says, and work in both text and voice.

### The persona here is assembled per session, not picked from a library

Unlike Hiring Manager Mode, the Interview Simulator's persona is built fresh for each session from three inputs: the specific job description, light company research (via `web_search`), and the candidate's own (rebuilt) resume. That composition happens once, at session start, and is cached in the graph's state for the rest of the interview.

### The conversation graph

```
┌────────────────┐   ┌──────────────┐   ┌──────────────┐   ┌───────────────────┐
│ build_question   │──▶│ ask_question  │──▶│ receive_answer│──▶│ (conditional)      │
│ bank (once)      │   └──────────────┘   └──────────────┘   └─────────┬─────────┘
└────────────────┘                                                     │
                                              follow-up warranted ──────┤────── move to next question
                                                     │                          │
                                                     ▼                          ▼
                                          ┌────────────────┐         ┌────────────────┐
                                          │ ask_followup_llm│        │ compute_feedback│
                                          └────────┬────────┘        │ (pace, fillers, │
                                                    │                 │  STAR structure)│
                                                    └────────▶ ask_question (loop)
```

Every turn writes to the Postgres checkpointer, so a dropped call or a backgrounded app resumes exactly mid-question — the same primitive from §3.2, no special-case code needed.

### Voice mode

Claude doesn't do audio natively, so voice mode wraps the same text graph in a streaming audio pipeline:

```
mic audio ──▶ STT (streaming, word-level timestamps) ──▶ [ same LangGraph text graph ] ──▶ TTS ──▶ speaker
```

The word-level timestamps a streaming STT provider returns are what make the "pace" and "filler word" feedback tags real measurements instead of vibes — words-per-minute and pause length are computed directly from that timing data, not guessed by the LLM.

**Privacy, matching the product plan's guardrail:** only the transcript and the derived feedback scores are persisted to `interview_sessions`. Raw audio is not stored server-side by default — it's processed in the streaming pipeline and discarded, consistent with session recordings being opt-in.

---

## 8. Build Sequence

Mirrors the original product roadmap — ship the lowest-risk, highest-validation piece first.

| Step | What | Why first/next |
|---|---|---|
| 1 | Stand up Postgres + `pgvector`; migrate nothing in the existing Node gateway yet | Foundation every later step needs |
| 2 | Scaffold the Python Agent Service (FastAPI + LangGraph); port the Resume/ATS graph, add RAG grounding | Lowest risk — the logic already works in Node, this adds retrieval and persistence |
| 3 | Hiring Manager persona graph + seed `persona_anchors` for the four launch personas | Needed before Auto-Apply, since fit-scoring reuses it |
| 4 | Auto-Apply: ATS-platform API integrations first, `web_search` discovery second, Playwright fallback + consent-gate interrupt last | Structured integrations de-risk before touching browser automation |
| 5 | Interview Simulator: text mode first, voice (STT/TTS) second | Validates the conversation graph before adding the audio pipeline |

I can start scaffolding the Python Agent Service — Step 1 and the Resume/ATS graph from Step 2 — whenever you're ready; this document is the spec for it.

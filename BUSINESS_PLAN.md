# AURA MATCH — Business & Launch Plan

Pricing, unit economics, first-1,000-users marketing, and the Alpha → Beta → Public rollout.

---

## 1. Pricing Model

**Recommendation: freemium subscription with soft usage caps, plus optional top-up packs for overage.** Not a raw pay-per-credit system — for this specific audience, that's the wrong call. People running a job search are already anxious about money and about a countdown they can't control (their savings, their timeline). Making them also watch a *credit balance* tick down every time they use the product that's supposed to be reducing their stress adds friction exactly where you can't afford it. Subscriptions with generous limits, plus a rarely-needed top-up option, get you the same cost protection without the anxiety UX.

### Tiers

| | **Free** | **Pro — $29/mo** | **Unlimited — $59/mo** |
|---|---|---|---|
| ATS Scan + Gap Report | Unlimited | Unlimited | Unlimited |
| AI-rebuilt resume | 1 / month | Unlimited | Unlimited |
| Hiring Manager Mode | Score only | Full line-by-line feedback, all personas | Full line-by-line feedback, all personas |
| Automatic Job Search & Apply | — | 50 applications / month | Unlimited (fair-use capped, see §2) |
| Interview Simulator | — | 10 sessions / month | Unlimited (fair-use capped) |
| Resume version history | 3 versions | Unlimited | Unlimited |

The free tier is not a stripped-down demo — the ATS scan is the product's best acquisition asset, so it stays completely unmetered. A specific, slightly alarming, personalized number ("62% ATS match") is what gets shared, screenshotted, and talked about; paywalling it would kill the exact mechanism that gets you your first users (§3). What's gated is the *effort* — the rebuild, the full manager critique, the applying, the interview prep — the parts that cost real compute and that someone in an active search will pay for without hesitation once the free scan has already shown them the problem.

**Top-up packs**, not a credit economy: "10 more applications this week — $4.99" or "3 more interview sessions — $6.99," available to Pro users who hit a monthly cap early. This is the "mix of both" done safely — it exists for the rare overage, not as the primary way anyone is expected to interact with pricing.

### The insight that should shape billing: success is your churn event

This product is structurally different from most subscriptions. A typical SaaS user churns because they got bored, found a competitor, or stopped needing the category. Here, the *best possible outcome* — getting hired — is also the moment a Pro subscriber cancels. That's good for your brand and terrible for naive MRR modeling if you don't plan around it.

Two consequences for how you should actually bill:

- **Lead with monthly, don't push annual hard.** A user who only needs the product for six to ten weeks and gets pushed into an annual plan will either churn-and-refund (reputation cost) or feel cheated into overpaying (worse reputation cost, on a platform whose whole pitch is trustworthiness). Save the annual discount for the segment where it's genuinely the right fit — the "passive candidate" persona from the product plan, who wants Aura running quietly in the background for a year, not urgently for six weeks.
- **Build a win-back loop, not just a retention loop.** Someone who got hired via Aura is a near-perfect referral source — they know other people job-hunting right now. A short "congrats, want $10 off for a friend who needs this?" flow at the moment of cancellation turns your highest-churn event into your highest-intent acquisition channel, instead of just eating the loss.

---

## 2. Managing AI Costs

The real risk here isn't that AI tokens are expensive — measured against current Claude pricing, they're not, per §2.1 below. The real risk is *unbounded usage* on the agentic features (Auto-Apply's browser automation, the Interview Simulator's voice pipeline) if nothing caps them. Five concrete controls, in order of impact:

1. **Match model tier to task, and make that a paid-tier feature, not just a cost hack.** ATS scanning is mechanical structured extraction — run it on Haiku 4.5. Resume rebuilds and Hiring Manager scoring benefit from stronger reasoning — run those on Sonnet 5 for Pro/Unlimited users. This is legitimately a value differentiator, not just cost control: "Pro gets our most capable AI" is true, not a fake paywall.
2. **Cache everything reusable.** System prompts, persona rubrics, and calibration anchors (DATABASE_ARCHITECTURE.md §3) are near-identical across thousands of calls — prompt caching cuts the repeated-prefix cost by roughly 90%. This is close to a free lunch; implement it before anything else on this list.
3. **Batch what isn't real-time.** The daily job-search sweep doesn't need sub-second latency — route it through the Batch API for 50% off. The user is asleep when it runs anyway.
4. **Two-stage retrieve-then-rank, already designed in.** DATABASE_ARCHITECTURE.md's vector pre-filter means the expensive LLM fit-scorer only ever runs against a shortlist, never against the full job database. This is already the plan — just confirm it's actually enforced in the code, since it's the single biggest lever on Auto-Apply's cost.
5. **Hard fair-use ceilings, even on "Unlimited."** "Unlimited" in consumer subscriptions always means "generous cap, not literally infinite" — say so in the ToS (e.g., 500 applications/month, 60 interview sessions/month) so one outlier user can't quietly cost more than the other 200 Unlimited subscribers combined.

### 2.1 — Illustrative unit economics (current Claude pricing)

Rough token estimates, current published per-model pricing. Treat this as a sanity check, not a final number — instrument the real thing (see below).

| Action | Model | Est. cost |
|---|---|---|
| ATS Scan | Haiku 4.5 ($1 / $5 per MTok) | ~$0.004 |
| Resume Rebuild | Sonnet 5 ($3 / $15 per MTok) | ~$0.04 |
| Hiring Manager Score | Sonnet 5 | ~$0.03 |
| Interview session, text, ~20 turns | Sonnet 5 | ~$0.17 |
| Job-search sweep (vector pre-filter + LLM scoring on shortlist) | Sonnet 5 | ~$0.01/day |

A realistic Pro user in a given month — 10 scans, 5 rebuilds, 3 manager scores, 30 applications, 2 interview sessions — costs roughly **$1 in pure LLM tokens** against a $29 subscription. Voice mode adds STT/TTS costs on top (get a real quote from whichever vendor you pick — that number isn't estimated here), and the actual infrastructure cost of running Playwright browser sessions for Auto-Apply's fallback path is very likely a bigger line item than the AI tokens themselves. **Don't over-rotate on token cost anxiety — watch the agentic infrastructure spend instead**, since that's where the real variance lives.

**Instrument this for real, don't guess forever.** The backend already logs `response.usage` on every Claude call (`server/src/anthropicClient.js`). Add one table that records `{user_id, action_type, input_tokens, output_tokens, model, cost_estimate}` per call, and you have real per-feature, per-tier cost data within the first two weeks of Alpha — replace this table with that data before setting final public pricing.

---

## 3. Getting First 1,000 Users

### Pick one beachhead, not all three personas at once

The product plan names three audiences — urgent active seekers, career switchers, passive candidates. For the first 1,000, focus entirely on **urgent active seekers**. They convert fastest (urgency drives willingness to pay immediately), they're the easiest to find (layoffs create identifiable, searchable communities), and they're the most likely to talk about a tool that visibly helped in a short window. The other two personas are real, but they're a Month 3+ expansion, not a launch strategy.

### Where to actually post — matched to that audience, not generic "social media"

| Channel | Approach | Why it works for this audience specifically |
|---|---|---|
| **Reddit** (r/resumes, r/jobs, r/layoffs, r/cscareerquestions) | Answer real resume-critique threads with genuinely useful, non-promotional advice; mention the tool only when it's actually relevant, offer to run someone's resume through it for free | Reddit punishes promotion and rewards authenticity — this is a trust-building channel, not a blast channel |
| **TikTok / Reels / Shorts** | Screen-recorded "AI scores my resume live" using the score-ring reveal — the UI was already designed for exactly this kind of moment | "CareerTok" is an established, large content niche; a visual score reveal is inherently watchable |
| **LinkedIn** | Founder build-in-public posts, career-pain-point content, direct engagement with #OpenToWork posts | The algorithm rewards founder-story and career-advice content; the audience is already there self-identifying as job-searching |
| **Layoff-specific Slack/Discord groups** | Show up and help before mentioning the product at all | These form fast after any large layoff and are extremely high-intent, low-noise communities |
| **A free, no-signup web scan** | A single web page that runs just the ATS scan, no app download required, optimized for "free ATS resume checker" search intent | High-intent search traffic that compounds over time, unlike a one-off social post — and it's a natural on-ramp into the full Flutter/web app |
| **Product Hunt** | Launch day push once Beta is stable | Concentrated spike, early-adopter audience, potential press pickup |

### Make the free scan shareable — the referral loop is already built into the product

The ATS score is a personal, slightly provocative stat — exactly the shape that gets shared (think Spotify Wrapped, Duolingo streaks). Add one feature: a shareable result card ("I scored 82% ATS match with Aura") generated at the end of every scan. This turns your top-of-funnel free feature into a distribution mechanism at near-zero additional cost.

### A believable path to 1,000, with numbers

| Stage | Assumption | Result |
|---|---|---|
| Organic reach (Reddit + TikTok + LinkedIn combined, first 6 weeks) | ~150,000 impressions | — |
| Click-through to the free scan page | ~3% | ~4,500 visitors |
| Visitors who actually run the free scan | ~25% | ~1,100 completions |
| Scan completions who create an account | ~40% | ~450 accounts |
| Plus SEO/referral-card traffic over the same window | — | ~600 more accounts |
| **Total accounts, ~6 weeks** | | **~1,050** |

These are realistic, not optimistic, consumer-funnel benchmarks — treat this table as the thing to beat, not a guarantee, and instrument every stage of it from day one so you know which assumption is wrong if the real number comes in low.

---

## 4. Roadmap to Launch

Mapped directly onto the phased technical build already specified across the three architecture documents — the business stages and the engineering stages are the same timeline, not two separate plans.

| Stage | Users | Feature scope | Primary goal | Exit criteria |
|---|---|---|---|---|
| **Alpha** | 20–50, invited (network + a few from target communities), free | Smart Resume Builder + Hiring Manager Mode only — no Auto-Apply, no Interview Simulator yet | Validate the core "wow" moment actually delights; catch obvious bugs and UX friction | 5+ unprompted testimonials; ATS scan → rebuild completion rate above 70% |
| **Beta** | Few hundred, waitlist → admitted in waves | Adds Auto-Apply (consent-gate, tight allow-list, low daily caps) + Interview Simulator (text mode only) | Stress-test the riskiest systems at controlled volume; validate the §2 cost model against real logged usage; soft-launch pricing | Consent-gate and daily caps hold under real usage with zero incidents; real per-feature cost data confirms §2.1 estimates are in the right range |
| **Public Launch** | Open, Product Hunt + full §3 push | All four features live; final pricing live; referral loop live | Hit 1,000 active users within ~6 weeks of launch | Retention and conversion tracking in place before the first user arrives, not bolted on after |

The sequencing matters here specifically because of Auto-Apply: it's the one feature with real legal/reputational risk (application-submission ToS, the consent-gate), which is exactly why it's held out of Alpha and only turned on for Beta's smaller, more observable audience before it ever reaches a Product Hunt-scale crowd.

---

Ready to start on whichever piece is most urgent — instrumenting the cost-tracking table, building the shareable-scan feature, or standing up the Alpha invite flow.

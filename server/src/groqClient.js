import Groq from "groq-sdk";

// Deep analysis (ATS scan, resume rebuild, hiring-manager scoring) gets the
// larger model; interactive chat (Q&A, interview simulation) gets the fast
// one. Both are overridable via env so ops can swap models with no deploy.
const MODELS = {
  deep: process.env.GROQ_DEEP_MODEL || "llama-3.3-70b-versatile",
  fast: process.env.GROQ_FAST_MODEL || "llama-3.1-8b-instant",
};

let client = null;

export function isConfigured() {
  return Boolean(process.env.GROQ_API_KEY);
}

function getClient() {
  if (!client) {
    client = new Groq({ apiKey: process.env.GROQ_API_KEY });
  }
  return client;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Retries transient failures with exponential backoff + jitter. Honors a
 * Retry-After header when Groq sends one (typical on 429); falls back to
 * backoff otherwise. Non-retryable errors (bad request, auth, etc.) throw
 * immediately — retrying those would just fail the same way four times.
 */
async function withRetry(fn, { maxRetries = 4, baseDelayMs = 800 } = {}) {
  let attempt = 0;
  for (;;) {
    try {
      return await fn();
    } catch (err) {
      const status = err?.status;
      const retryable = status === 429 || status === 500 || status === 503;
      if (!retryable || attempt >= maxRetries) throw err;

      const retryAfterHeader = err?.headers?.get?.("retry-after");
      const delayMs = retryAfterHeader
        ? Number(retryAfterHeader) * 1000
        : baseDelayMs * 2 ** attempt + Math.floor(Math.random() * 250);

      console.warn(`[groq] ${status} — retrying in ${delayMs}ms (attempt ${attempt + 1}/${maxRetries})`);
      await sleep(delayMs);
      attempt++;
    }
  }
}

async function chatCompletion({ model, system, messages, jsonMode }) {
  const groq = getClient();
  const fullMessages = [
    // Groq's JSON mode (like OpenAI's) requires the word "json" to appear
    // somewhere in the prompt, or the API rejects the request outright.
    { role: "system", content: jsonMode ? `${system}\n\nRespond with valid JSON only — no prose, no markdown fences.` : system },
    ...messages,
  ];

  const content = await withRetry(async () => {
    const completion = await groq.chat.completions.create({
      model,
      messages: fullMessages,
      ...(jsonMode ? { response_format: { type: "json_object" } } : {}),
    });
    return completion.choices[0]?.message?.content ?? "";
  });

  return content;
}

/**
 * Deep resume/document analysis — ATS scanning, resume rebuilding, hiring-
 * manager scoring. Uses the larger model. `system` should describe the
 * exact JSON shape expected in the reply — Groq has no schema-enforcement
 * parameter, so the shape lives in the prompt, not in a schema object.
 */
export async function analyzeResume({ system, prompt }) {
  const raw = await chatCompletion({
    model: MODELS.deep,
    system,
    messages: [{ role: "user", content: prompt }],
    jsonMode: true,
  });
  return JSON.parse(raw);
}

/**
 * Interactive chat — the AI Q&A resume conversation today, and the
 * Interview Simulator once that route exists. Uses the fast model so a
 * back-and-forth conversation doesn't feel like it's waiting on a report.
 */
export async function chatTurn({ system, messages }) {
  return chatCompletion({ model: MODELS.fast, system, messages, jsonMode: false });
}

export const GROQ_MODELS = MODELS;

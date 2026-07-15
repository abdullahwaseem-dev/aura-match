# AURA MATCH — Free LLM Provider Plan

Moving off paid APIs. Free keys from Groq, Google AI Studio, and OpenRouter, plus self-hosted Ollama as the no-limit fallback. Written so the whole team can follow it, not just whoever builds it.

---

## 1. The one idea that makes this simple

Groq, OpenRouter, and Ollama — and Google, if you use its newer compatibility endpoint — all speak the **same API shape** that OpenAI made popular: send a `messages` array to `chat.completions.create`, get a response back the same way. That means our backend doesn't need four different pieces of code for four different providers. It needs **one** function, and a list of providers to try it with.

```
Flutter App
    │  (never holds an API key — see §5)
    ▼
Node Gateway (server/)
    │  tries providers in order until one answers
    ▼
Groq → Google → OpenRouter → Ollama (your own server, never rate-limited)
```

---

## 2. Free API Options

### Groq — fast, generous, first choice

Groq runs open models (Llama, Gemma) on custom hardware that's unusually fast, and gives free API access.

1. Go to `console.groq.com`, sign in, click **API Keys → Create**.
2. Put it in `server/.env` as `GROQ_API_KEY`.
3. Done — no code changes needed beyond what's in §4, because Groq uses the OpenAI-compatible shape.

### Google AI Studio — Gemini, also free

1. Go to `aistudio.google.com/apikey`, click **Create API key**.
2. Put it in `server/.env` as `GOOGLE_API_KEY`.
3. Google also exposes an OpenAI-compatible endpoint for Gemini — same code path as Groq, just a different `baseURL`. Confirm the exact current endpoint path in Google's docs before wiring it up; API paths shift more often than the SDK-based ones.

### OpenRouter — one key, many free models

OpenRouter is a router in front of dozens of models, including several tagged `:free` (e.g. Llama models hosted by other providers, at no cost to you).

1. Go to `openrouter.ai/keys`, create a key.
2. Put it in `server/.env` as `OPENROUTER_API_KEY`.
3. Pick a model with `:free` in its name from their model list — that's what keeps it free.

### The code — one function for all three

```javascript
// server/src/llmProviders.js
export const PROVIDERS = [
  {
    name: 'groq',
    baseURL: 'https://api.groq.com/openai/v1',
    apiKey: process.env.GROQ_API_KEY,
    model: 'llama-3.3-70b-versatile', // check Groq's current model list — names change
  },
  {
    name: 'google',
    baseURL: 'https://generativelanguage.googleapis.com/v1beta/openai/',
    apiKey: process.env.GOOGLE_API_KEY,
    model: 'gemini-2.0-flash',
  },
  {
    name: 'openrouter',
    baseURL: 'https://openrouter.ai/api/v1',
    apiKey: process.env.OPENROUTER_API_KEY,
    model: 'meta-llama/llama-3.1-8b-instruct:free',
  },
];
```

Every provider above is called the exact same way, using the standard `openai` npm package (yes, even for Groq/Google/OpenRouter — the package just talks HTTP, it doesn't care who's on the other end):

```javascript
import OpenAI from 'openai';

async function callProvider(provider, messages) {
  const client = new OpenAI({ baseURL: provider.baseURL, apiKey: provider.apiKey });
  const response = await client.chat.completions.create({
    model: provider.model,
    messages,
    response_format: { type: 'json_object' }, // ask for valid JSON — see the honesty note below
  });
  return JSON.parse(response.choices[0].message.content);
}
```

**One honest note on quality:** Claude's structured-output feature (what `anthropicClient.js` uses today) *guarantees* the JSON matches an exact schema. Free open models are generally less reliable at this — `response_format: json_object` guarantees valid JSON *syntax*, but not that every field you expect is actually there. Parse defensively (check fields exist before using them) rather than assuming the shape is perfect every time.

---

## 3. Self-Hosting with Ollama

Ollama runs an open-source model on a server you control. Once it's running, it never rate-limits you and never costs per token — you're paying for the server itself, not for usage.

### Step by step

1. **Get a server with a GPU.** This is the part that isn't free — an 8B model (like Llama 3.1 8B) needs roughly 8–16GB of GPU memory depending on how it's compressed ("quantized"). A rented GPU box from RunPod, Lambda Labs, or a cloud provider's GPU instance works. A laptop GPU can run small models for local testing, but not for a server other people's requests hit.
2. **Install Ollama on that server:**
   ```bash
   curl -fsSL https://ollama.com/install.sh | sh
   ```
3. **Pull a model:**
   ```bash
   ollama pull llama3.1
   ```
4. **Run it** — Ollama starts a local API automatically on port `11434`.
5. **Lock it down before anyone else can reach it.** Ollama has **no built-in login or API key** — anyone who can reach port `11434` can use your GPU for free. Never expose it directly to the internet. Put it behind a reverse proxy (nginx or Caddy) that requires an API key header, or keep it reachable only over a private network/VPN between your Node gateway and the Ollama box.
6. **Add it to the provider list** — Ollama also speaks the OpenAI-compatible shape:
   ```javascript
   {
     name: 'ollama',
     baseURL: process.env.OLLAMA_BASE_URL, // e.g. http://your-server-ip:11434/v1
     apiKey: 'ollama', // Ollama ignores this value, but the SDK requires a non-empty string
     model: 'llama3.1',
   }
   ```

Put this one **last** in the provider list (§4) — it's the fallback with no limit, held in reserve for when the free API keys are tapped out.

---

## 4. Handling Limits

### What actually happens when you hit a limit

A "rate limit" means a provider is saying "slow down" — the request comes back with HTTP status **429**. It's not a crash, it's a specific, checkable signal, which is exactly why it can be handled in code instead of showing the user an error.

### The fix: try the next provider, don't just fail

This is the real answer to "what happens when the free key stops working" — you have four of them, so one running dry doesn't take the feature down:

```javascript
// server/src/llmClient.js
import OpenAI from 'openai';
import { PROVIDERS } from './llmProviders.js';

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function callWithFallback(messages) {
  let lastError;

  for (const provider of PROVIDERS) {
    if (!provider.apiKey) continue; // skip any provider whose key isn't configured

    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        const client = new OpenAI({ baseURL: provider.baseURL, apiKey: provider.apiKey });
        const response = await client.chat.completions.create({
          model: provider.model,
          messages,
          response_format: { type: 'json_object' },
        });
        return JSON.parse(response.choices[0].message.content);
      } catch (err) {
        lastError = err;
        if (err.status === 429 && attempt === 0) {
          await sleep(1000); // brief pause, try this same provider once more
          continue;
        }
        break; // either a second 429, or a different error — move to the next provider
      }
    }
  }

  throw new Error(`All providers are unavailable right now: ${lastError?.message}`);
}
```

Read it top to bottom: try Groq. If Groq is rate-limited, wait a second and try Groq once more. Still limited? Move to Google. Still limited? Move to OpenRouter. Still limited? Move to your own Ollama server, which never runs out. Only if literally everything fails does the caller see an error.

### If every provider really is busy — don't leave the user staring at a spinner

This is exactly the scenario DATABASE_ARCHITECTURE.md's `background_jobs` table was designed for: if `callWithFallback` fails, don't hang the request — mark the job `failed` (or `queued` for a retry pass a minute later), and let the Flutter app show "Aura's a little busy — trying again shortly" instead of a raw error. The async job pattern already in the plan absorbs this automatically; nothing new to build for it.

---

## 5. How the Flutter App Connects

Short answer: **it doesn't, directly — and shouldn't.** None of these API keys ever go in the Flutter app, on any platform. A key shipped inside a compiled app (iOS, Android, or Web) can be pulled out by anyone who looks — that's true of a free key exactly as much as a paid one.

The Flutter app keeps calling the same Node gateway endpoints it already does (`/api/resume/scan`, `/api/resume/rebuild`, `/api/hiring-manager/score`). Everything in this document happens *behind* those endpoints, inside `server/`. Swapping Claude for Groq/Google/OpenRouter/Ollama is entirely a backend change — the Flutter app doesn't know or care which one answered.

---

## 6. Migration Checklist

1. Create free accounts and keys: Groq, Google AI Studio, OpenRouter. Add all three to `server/.env`.
2. Add `server/src/llmProviders.js` and `server/src/llmClient.js` from §2/§4 above.
3. In `server/src/anthropicClient.js`, swap the Claude call inside `structuredCall()` for `callWithFallback()`.
4. (Optional, when ready) Stand up an Ollama server, lock it down per §3, add it as the last provider in the list.
5. Test each route (`/scan`, `/rebuild`, `/score`) with only one provider's key set at a time, so you know each one actually works before relying on the fallback chain to hide a broken one.
6. Watch real usage for a week before assuming the free tiers hold — this is the moment to find out for real, not guess.

Ready to actually wire this into `server/` whenever you want it built, not just planned.

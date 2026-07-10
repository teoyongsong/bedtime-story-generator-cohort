# Module 1 — Swap Ollama for the Gemini API

**Single fundamental:** Your backend can call a hosted LLM via SDK, not just a local one over HTTP.

The app you ran in Module 0 talked to Ollama over `http://localhost:11434` using `httpx`. In this module, the entire `ollama_service.py` file goes away and a new `gemini_service.py` takes its place — calling Google's Gemini through the `google-genai` SDK instead of hand-rolled HTTP. The user-visible behaviour is the same: ask a question, get an answer, see it in history. The wiring underneath is different.

> **Read the deletions first.** This is a *conversion* module. Open `app/services/ollama_service.py` from your Module 0 folder side-by-side with `app/services/gemini_service.py` here. The lesson is in *what disappeared* (`OLLAMA_BASE_URL`, the `httpx.Client.post(...)` call, the manual `messages` JSON, the response-dict drilling) as much as in *what's new*.

## Run

Get a free Gemini API key at <https://aistudio.google.com/apikey> first.

```bash
# from inside this folder (dist/module_01_swap_to_gemini/) — macOS / Linux / WSL2 Ubuntu:
source ../../venv/bin/activate    # only if (venv) isn't already in your prompt
cp .env.example .env              # this folder's contract: GEMINI_API_KEY-only (Ollama vars gone)
# edit .env to paste your real key from https://aistudio.google.com/apikey
uvicorn app.main:app --reload
```

Postgres still needs to be running (the `interactions` table from Module 0 is unchanged). You no longer need Ollama running — it's been completely replaced.

> **`KeyError: 'GEMINI_API_KEY'` at startup** means you skipped `cp .env.example .env`, or `.env` doesn't have the real key yet. Same loud-fail discipline as Module 0's `OLLAMA_BASE_URL` — different env var, identical shape.

## Verify

```bash
# /ask now hits Gemini:
curl -s -X POST http://localhost:8000/ask \
    -H "Content-Type: application/json" \
    -d '{"question":"What is FastAPI in one sentence?"}'
# Expected: {"answer": "<a coherent sentence>", "history": [...]}

# /healthz no longer reports Ollama:
curl -s http://localhost:8000/healthz
# Expected: {"postgres": true}    (no "ollama" key — that branch is gone)

# Postgres recorded the new model name:
psql "$DATABASE_URL" -tAc \
    "SELECT model_name FROM interactions ORDER BY id DESC LIMIT 1"
# Expected: gemini-2.5-flash-lite

# Or run the all-in-one check (server must be up):
./scripts/verify_module_1.sh
```

The first `/ask` call may take a couple of seconds (TLS handshake to Google's API + first-token latency). Subsequent calls are faster.

**Loud-fail check.** Comment out the `GEMINI_API_KEY` line in `.env` and try `uvicorn app.main:app` again. The app refuses to start with a clear error message. That's the same loud-fail discipline V1's Module 8 taught — only the line that raises is different.

## Try asking Gemini

This is an early-tier module — the prompts below are explicit and many on purpose. Later modules will fade them out. Read your edited code first; predict before you ask.

**Before you read the new code:**
> Open `app/services/ollama_service.py` from `dist/module_00_baseline/` and `app/services/gemini_service.py` from this folder side-by-side. List every line that disappeared and every line that appeared. For each disappeared line, tell me: was it doing real work in V1, or was it incidental? For each new line, tell me: what V1-line did it replace, or is it doing something genuinely new?

**About `genai.Client(...)`:**
> Why does the line `client = genai.Client(api_key=GEMINI_API_KEY)` sit at module level (runs once when the file is imported) rather than inside `call_gemini` (runs on every request)? What would change — concretely — if I moved it inside the function?

**About the `system_instruction` config:**
> In V1, the system prompt was a `{"role": "system", "content": SYSTEM_PROMPT}` dict inside the `messages` array we sent to Ollama. Here, it's `types.GenerateContentConfig(system_instruction=SYSTEM_PROMPT)` attached to a config object. Trace through what's actually being sent over the wire to Google in each case. What stayed the same conceptually? What's now hidden from us by the SDK?

**About `GEMINI_MODEL` being a constant:**
> `OLLAMA_MODEL` was an env var in V1. `GEMINI_MODEL = "gemini-2.5-flash-lite"` is a hardcoded constant here. Argue both sides: when does it make sense to make a model name a hardcoded constant, and when does it make sense to make it an env var? Then tell me which side this module's doctrine is on, and why.

**Curiosity / "what if":**
> What happens if I delete the `except genai_errors.APIError:` block entirely and let the SDK's exception bubble up? Try it (just in your head — predict the response shape and HTTP status code). Then put the block back and explain why catching-and-re-raising-as-`HTTPException(502)` is doctrine-compliant here even though the doctrine forbids "try/except that catches and re-raises with no added value."

**About the `/healthz` change:**
> The Ollama branch of `/healthz` was deleted entirely — we did *not* replace it with a Gemini probe. Why not? Argue it from the cost-and-quota model of a paid hosted API vs. the cost-and-quota model of a localhost daemon.

**Self-check before you move to Module 2:**
> Module 2 replaces the single `question` textarea with a multi-field form (child_name, characters, setting, plot). Predict: what concept is Module 2 teaching that Module 1 wasn't? Hint: look at what kind of input the LLM is currently receiving, and what kind of input you'd need to give it to write a *bedtime story* instead of just answering a question.

---

**Defend It (do not paste this into Gemini — answer it yourself):**
> *What does calling Gemini through the `google-genai` SDK give us that an `httpx.post()` to `generativelanguage.googleapis.com` — the shape we used for Ollama — wouldn't?*

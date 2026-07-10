# Module 0 — Baseline reset

**Single fundamental:** Conversion courses depend on a known starting point. Anchor your baseline before you transform it.

This module is **the V1 final state of the prior FastAPI Local LLM Question Log course**, copied byte-identical from `app-lego-blocks/dist/module_08_configuration/`. There's no new code in Module 0 — that's the point. Every module past 0 transforms this baseline; if two students start from two different "edited V1s," the same Module 1 instructions produce two different outcomes and the cohort drifts. Module 0 is the contract that says *"we are all starting here, exactly here."*

What you have in this folder:
- A working FastAPI app (`app/main.py`) with a single textarea on a `/` page.
- An Ollama-backed `/ask` endpoint that calls a local `llama3.2` model over HTTP.
- A `/healthz` endpoint that probes both Postgres and Ollama.
- A `/history` endpoint that returns the recent ten Q&A pairs.
- A Postgres `interactions` table (one INSERT per `/ask`, recorded with the model name).
- The V1 doctrine you already shipped: `os.environ[...]` loud-fail at import time, three plain env vars, no Pydantic-settings, no async, no streaming, no tests.

Module 1 deletes the Ollama wiring; Module 2 deletes the textarea; Module 6 drops the `interactions` table. **By Module 7 nothing of this V1 surface remains.** This is your last look at the V1 app you shipped — the baseline before the conversion begins.

## Run

From this folder, with the shared venv at the repo root already created and dependencies installed (see the cohort `README.md`):

```bash
source ../../venv/bin/activate    # only needed if (venv) isn't already in your prompt
cp .env.example .env              # required — app uses load_dotenv() and will KeyError without it
uvicorn app.main:app --reload
```
(macOS / Linux / WSL2 Ubuntu — same commands.)

`.env.example` already has the three V1 vars filled in with sensible local defaults (`DATABASE_URL`, `OLLAMA_BASE_URL`, `OLLAMA_MODEL`). If your local Postgres uses a different `postgres` password, edit `DATABASE_URL` in `.env` to match. Otherwise leave the file as-is.

> **If uvicorn crashes with `KeyError: 'OLLAMA_BASE_URL'`** at import time (before binding the port), the `.env` file is missing from this folder. Run `cp .env.example .env` and re-run uvicorn. That's V1's loud-fail discipline working correctly — Module 1 will rediscover the same shape with `KeyError: 'GEMINI_API_KEY'`.

## Verify

The host environment (Postgres running, Ollama running, model pulled, table present) is what matters in Module 0. From this folder OR from the repo root, run:

```bash
./scripts/verify_setup.sh
```
(macOS / Linux / WSL2 Ubuntu — same command.)

Expected: every check green, ending with *"All checks passed. You're ready for Module 1."*

If a check fails, **the script prints the exact next-step command** on the same line as the ✗. Common failures: Postgres not started, Ollama not running, `llama3.2` not pulled, database missing, table missing. Paste the printed fix command and re-run.

Then smoke-test the running app:

```bash
# /healthz reports both backing services:
curl -s http://localhost:8000/healthz
# Expected: {"ollama": true, "postgres": true}

# /ask round-trips a question through Ollama + Postgres:
curl -s -X POST http://localhost:8000/ask \
    -H "Content-Type: application/json" \
    -d '{"question":"What is FastAPI in one sentence?"}'
# Expected: {"answer": "<llama3.2's response>", "history": [...]}
```

Open <http://localhost:8000> in a browser. Type a question, hit Ask. You see the answer rendered, plus the recent Q&A history below. **That's the V1 Q&A app, exactly as you shipped it at the end of the prior course.**

## Try asking Gemini

You'll get an AI partner (Antigravity, Cursor, Claude Code) loaded with `AGENTS.md` from the cohort repo root. The course is designed to be built *with* an AI in the loop — these Module 0 prompts get you used to how the AI partner behaves under the doctrine.

**Re-anchor your mental model:**
> Walk me through what `verify_setup.sh` is checking, in execution order. Don't tell me the fix for any failure — just tell me what each line is verifying and why that probe is in the script.

**Predict before you run:**
> If I stopped Postgres right now (`brew services stop postgresql@17`), what's the first error message I'd see? Where does it surface — at uvicorn startup, on first request, or only when I hit `/ask`? Trace through `app/main.py` and `app/services/interaction_service.py` to predict, then I'll actually stop Postgres and we'll compare.

**About the V1 loud-fail you already shipped:**
> `app/services/ollama_service.py` line 5 reads `OLLAMA_BASE_URL = os.environ["OLLAMA_BASE_URL"]` at module import time. Why is that more honest than `os.environ.get("OLLAMA_BASE_URL", "http://localhost:11434")` even though the second form has a sensible default? Argue both sides, then tell me which side V1's Module 8 doctrine took and why.

**Curiosity / what if:**
> Module 1 will delete this entire `app/services/ollama_service.py` file and replace it with `gemini_service.py` calling Google's hosted Gemini SDK. Predict: what stays the same in `app/main.py` between Module 0 and Module 1? What has to change? Hint: read `app/main.py` and notice how `ollama_service` is imported and called.

---

**Defend It (do not paste this into Gemini — answer it yourself):**

> *Why is anchoring Module 0 to `app-lego-blocks/dist/module_08_configuration/` (and not your own edited V1 working tree) worth its own module — instead of just being a one-line "make sure your V1 still runs" check at the start of Module 1?*

# Module 6 — Story library (re-hear yesterday's story)

**Single fundamental:** The same persistence pattern carries from V1's Q&A log to a story library — schema follows what the user actually re-uses.

Persistence comes back. The V1 `interactions` table — dead in the codebase since Module 2, kept in the database through Modules 3–5 — is dropped. A new `stories` table takes its place: columns named for the bedtime-story domain (`child_name`, `characters`, `setting`, `plot`, `body`, `model_name`, `created_at`), with a composite index on `(child_name, created_at DESC)` to serve the *one* query that matters: *all stories for this child, latest first.* A new `app/services/story_service.py` (sibling to `gemini_service.py`) holds two functions — `save_story`, `fetch_recent_stories` — shaped exactly like the V1 `interaction_service.py` Module 2 deleted. *The pattern carries; the names follow the new domain.* The `/story` handler grows by one line (`save_story(payload, story_text)` after generation). A new `GET /stories?child_name=...` endpoint serves retrieval. The browser gets a "Past stories" panel inside the form pane — populated whenever the `child_name` field loses focus, click any saved story to render it *instantly* in the story-pane (no Gemini call; the words from the database are the same words the child fell asleep to last night).

> **The Defend-It is the heart of this module.** Why store the `body` (the generated story) and not just the four inputs that produced it? Three reasons in one breath: regenerating gives a *different* story (LLMs are non-deterministic), regenerating costs a Gemini call, and the child wants the same words. That's the curriculum-flip's whole rationale, codified.

## Run

```bash
# from inside this folder (dist/module_06_story_library/) — macOS / Linux / WSL2 Ubuntu:
source ../../venv/bin/activate    # only if (venv) isn't already active
cp .env.example .env              # if you don't already have one in this folder

# One-time migration: DROP interactions, CREATE stories. Requires $DATABASE_URL
# exported in your shell — not just present in .env. If $DATABASE_URL isn't set:
#     export DATABASE_URL=postgresql://postgres:postgres@localhost:5432/llm_question_log
# Symptom if missing: `psql: ... FATAL: database "<your-username>" does not exist`.
psql "$DATABASE_URL" -f sql/002_create_stories.sql

uvicorn app.main:app --reload
```

Same `.env` contract (`DATABASE_URL`, `GEMINI_API_KEY`). After the migration, the V1 `interactions` table is gone; the new `stories` table is in its place with an empty row count.

## Verify

```bash
# Generate a story (POST /story now persists):
curl -s -X POST http://localhost:8000/story -H "Content-Type: application/json" \
    -d '{"child_name":"Aisha","characters":"an owl and a fox","setting":"enchanted forest","plot":"looking for the moon"}'

# Confirm the row landed:
psql "$DATABASE_URL" -c "SELECT id, child_name, plot, LEFT(body, 60) FROM stories ORDER BY id DESC LIMIT 1"

# Retrieval works:
curl -s "http://localhost:8000/stories?child_name=Aisha"

# All-in-one:
./scripts/verify_module_6.sh
```

In the browser, generate stories for the same `child_name` two or three times. Click on an older story in the "Past stories" panel — it renders instantly in the story-pane, no spinner, no Gemini call. *Same words every time, on demand.*

## Try asking Gemini

**Late tier.** Two prompts. The build phase is winding down — by now you have your own way of asking, and the prompts below are starters.

**Articulate the gain:**
> Convince me — using the schema and the `/story` handler change only, no hand-waving — that storing the `body` along with the four inputs was the right call. If I push back ("you're wasting space; just regenerate"), push back harder.

**Pick something that surprised you and explore it.**
> Open `app/services/story_service.py` and `sql/002_create_stories.sql`. Pick one design choice that surprised you (the composite index? the `model_name` column? the `try/except` shape mirroring V1? the `LIMIT 5` cap with no pagination? the click-to-rehear behaviour serving from the DB and not Gemini?). Write a prompt to ask Gemini about it. Share what Gemini said with your peer in the breakout room.

---

**Defend It:**
> *Why does the `stories` table store both the four input fields (`child_name`, `characters`, `setting`, `plot`) AND the generated `body` — couldn't we just store the inputs and re-generate when needed?*

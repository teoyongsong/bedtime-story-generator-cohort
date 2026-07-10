# Module 2 — Replace the textarea with a structured form

**Single fundamental:** Richer typed input shapes the prompt the model sees.

The Module 1 app called Gemini with a single string the user typed into a textarea. In this module, that input becomes a structured form with four named fields (`child_name`, `characters`, `setting`, `plot`) and a Pydantic schema (`StoryRequest`) that names them. The endpoint renames from `/ask` to `/story` because the verb has changed — this app no longer answers questions, it generates stories. The V1 persistence layer (`/history`, `interactions` table writes, `interaction_service.py`) is **deleted entirely**: the Q&A schema doesn't fit the new domain, and Module 6 will reintroduce persistence with a `stories` table that actually does.

> **Read the deletions first.** This module is delete-heavy on purpose. Open `app/services/interaction_service.py` and `app/schemas.py` from your Module 1 folder side-by-side with this folder. The whole `interaction_service.py` file is gone; three Pydantic classes (`AskRequest`, `AskResponse`, `Interaction`) become two (`StoryRequest`, `StoryResponse`); two endpoints (`/ask`, `/history`) become one (`/story`). The lesson is that *naming follows the domain* — not the other way around.

## Run

```bash
# from inside this folder (dist/module_02_form_input/) — macOS / Linux / WSL2 Ubuntu:
source ../../venv/bin/activate    # only if (venv) isn't already active
cp .env.example .env              # if you don't already have one in this folder

# No new dependencies (deps come from the repo-root union venv); no schema migration.
uvicorn app.main:app --reload
```

Postgres still needs to be running (the V1 `interactions` table sits there unused — that's expected; Module 6 will drop it). `GEMINI_API_KEY` is the same contract as Module 1 — your real key from <https://aistudio.google.com/apikey> in `.env`.

Then open <http://localhost:8000> in a browser. Fill in the form (try `child_name=Aisha, characters=an owl and a fox, setting=enchanted forest, plot=looking for the moon`) and click **Generate story**. You should see a short bedtime story appear below the form.

## Verify

```bash
# /story works:
curl -s -X POST http://localhost:8000/story \
    -H "Content-Type: application/json" \
    -d '{"child_name":"Aisha","characters":"an owl and a fox",
         "setting":"enchanted forest","plot":"looking for the moon"}'
# Expected: {"story":"<a coherent short bedtime story mentioning Aisha, the owl, the fox, the forest>"}

# Pydantic catches missing fields with a helpful 422:
curl -s -X POST http://localhost:8000/story \
    -H "Content-Type: application/json" -d '{"child_name":"Aisha"}'
# Expected: 422 listing every missing field

# Old endpoints are gone:
curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:8000/ask -d '{}'
# Expected: 404
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/history
# Expected: 404

# All-in-one (server up + GEMINI_API_KEY exported):
./scripts/verify_module_2.sh
```

The first call may take a couple of seconds (Gemini latency); subsequent calls are faster. Run the same form twice — the two stories will differ in wording. That's the LLM doing its job, not a bug.

## Try asking Gemini

This is still an early-tier module — explicit prompts, many of them. Read your edited code first; predict before you ask.

**Before you read the new code:**
> Open `app/schemas.py`, `app/main.py`, and `app/templates/index.html` from `dist/module_01_swap_to_gemini/` and from this folder side-by-side. Make a list of every line that disappeared and every line that appeared. For each disappeared line, ask: was it doing real work in Module 1, or was it incidental? For each new line, ask: what Module-1 line did it replace, or is it doing something genuinely new?

**About `StoryRequest` having four fields:**
> Why is `StoryRequest` four typed fields (`child_name`, `characters`, `setting`, `plot`) instead of one `prompt: str` that the form pre-formats client-side and sends as-is? Predict what would change — concretely — if I moved the f-string concatenation from the backend handler into the browser's JavaScript. What would Pydantic stop being able to do for me?

**About the `/ask` → `/story` rename:**
> The endpoint name changed. The V1 verb was *ask* (a question, expecting an answer). The new verb is *story* (request a story, expecting a story body). Argue both sides: when does it make sense to rename an endpoint when its meaning changes, and when does it make sense to keep the old name for "backwards compatibility"? Then tell me which side this module's doctrine lands on, and why this teaching repo has the latitude to be strict about it.

**About the deleted persistence layer:**
> `app/services/interaction_service.py` is *gone*. So is the `/history` endpoint. The `interactions` table in Postgres is still sitting there, untouched. Trace through what would happen if I tried to call the old `save_interaction()` from the new `/story` handler — line by line, what would the schema mismatch produce? Now ask: why is dropping the file better than commenting out the call and leaving the file in place "in case Module 6 needs it"?

**Curiosity / "what if" — the deliberate inline ugliness:**
> The `/story` handler builds the Gemini prompt inline with an f-string concatenation. There's even a comment that says *"Module 3 lifts this inline f-string into compose_story_prompt(payload)."* Why is the refactor *deferred* to Module 3 instead of done here? What's the cost — to the lesson, not to the code — of refactoring it now?

**About Pydantic vs. browser validation:**
> The form has `required` attributes on `child_name` and `plot`. The Pydantic model has *no* defaults — every field is required at the type level. The handler *also* checks for non-blank `child_name` and `plot` and returns a 400 with a friendly message. Three layers of validation for the same constraint. For each layer, ask: what does this layer catch that the layers above and below would miss?

**Self-check before you move to Module 3:**
> Module 3 introduces `compose_story_prompt(req: StoryRequest) -> str` and refactors the inline f-string into it. Predict: what *exactly* will be different about Module 3's slide BEFORE/AFTER blocks compared to Module 2's? Hint: count the lines in `/story` before and after, and ask what fundamental that line-count change is meant to teach.

---

**Defend It (do not paste this into Gemini — answer it yourself):**
> *Why is the inline `prompt = f"Write a short bedtime story..."` block deliberately ugly in this module instead of being lifted into a `compose_story_prompt()` helper from the start?*

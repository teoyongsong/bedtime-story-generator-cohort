# Module 3 — Compose the user prompt from form fields

**Single fundamental:** Prompt composition is itself a piece of code with rules and care.

This module is a pure refactor. The user-visible behaviour does not change — the same form inputs produce the same kind of bedtime story. What changes is *where the prompt lives*: Module 2's inline f-string inside the `/story` handler is lifted into a new file `app/prompt.py`, behind a function `compose_story_prompt(req: StoryRequest) -> str`. That single move makes the prompt template a design surface you can edit, read, and call in isolation — instead of one buried in HTTP-handler glue.

> **The lift is small in lines but big in shape.** Read `app/main.py` and notice the handler is now four operations, each with a name: validate, compose, call, return. Then open the new `app/prompt.py` — that's the file you'll edit when you want to change how the prompt sounds. Two files, two concerns. Module 2's handler had both concerns tangled together.

## Run

```bash
# from inside this folder (dist/module_03_prompt_composition/) — macOS / Linux / WSL2 Ubuntu:
source ../../venv/bin/activate    # only if (venv) isn't already active
cp .env.example .env              # if you don't already have one in this folder

# No new dependencies, no schema migration.
uvicorn app.main:app --reload
```

Same `.env` contract as Module 1 (`DATABASE_URL`, `GEMINI_API_KEY`). Postgres still needs to be running. Open <http://localhost:8000>, fill the form, click **Generate story**.

## Verify

```bash
# /story still does the work — same shape, different code path:
curl -s -X POST http://localhost:8000/story \
    -H "Content-Type: application/json" \
    -d '{"child_name":"Aisha","characters":"an owl and a fox",
         "setting":"enchanted forest","plot":"looking for the moon"}'
# Expected: {"story":"<a coherent short bedtime story>"}

# The function is now testable in isolation — no uvicorn, no Gemini call needed:
python -c "
from app.schemas import StoryRequest
from app.prompt import compose_story_prompt
req = StoryRequest(child_name='  Aisha  ', characters='an owl', setting='forest', plot='moon')
print(compose_story_prompt(req))
"
# Expected: a multi-line string starting with 'Write a short bedtime story for a child named Aisha.'
# Note: the leading/trailing spaces around 'Aisha' are gone — the .strip() did its job.

# All-in-one (server up + GEMINI_API_KEY exported):
./scripts/verify_module_3.sh
```

Run the same form payload twice in the browser. The two stories will differ in wording — same prompt, non-deterministic LLM. *That's not a regression*; the model's job is to be creative.

## Try asking Gemini

This is now a **middle-tier** module — the prompts below are fewer (4) and lean more on "explain the design choice" than "predict what will happen." You're past the point of needing every concept laid out; you're at the point of articulating *why* the design is the way it is.

**Trace through the change:**
> Open `app/main.py` from `dist/module_02_form_input/` and from this folder side-by-side. Walk me through every difference in the `/story` handler. The handler shrank from twelve lines to six — but is it doing less work, or the same work in fewer places? Trace each operation in the new handler back to the line(s) it replaced in the old one.

**Explain the design choice — file location:**
> The new file is `app/prompt.py` — peer to `app/schemas.py`, **not** under `app/services/` next to `gemini_service.py`. Argue why. What does the `services/` folder mean in this codebase, and what would be wrong about classifying `compose_story_prompt` as a service?

**Explain the design choice — the two small additions:**
> The lifted function isn't *just* the inline f-string in a `def`. It also adds (a) `.strip()` on every field value and (b) a multi-line structure with newlines between labelled sections, instead of Module 2's single-line space-separated version. For each of those two additions, ask: what concrete problem does it solve, and why is the prompt-composition file the right place to solve it (rather than the handler, the schema, the form, or the LLM service)?

**About a surprise — refactoring without changing behaviour:**
> Run the same form payload through the Module 2 app and through the Module 3 app. The stories will be different — but they'll be the *same kind* of different they'd be if you ran Module 2 twice with the same payload. So we changed code without changing behaviour, statistically. In a production codebase you'd be told "don't refactor without a behaviour-preserving test." We don't have tests in V1. How would you convince a sceptical reviewer that this refactor is safe? (Hint: the answer involves the *new* property the function has that the inline f-string didn't.)

---

**Defend It (do not paste this into Gemini — answer it yourself):**
> *We didn't change behaviour — the same inputs produce the same kind of prompt, which produces (statistically) the same kind of story. What did we gain by extracting `compose_story_prompt` into its own function in its own file?*

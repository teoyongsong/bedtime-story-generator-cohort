# Module 4 — Strengthen the system prompt for child safety + bedtime tone

**Single fundamental:** Production system prompts include safety constraints, not just style guidance.

The system prompt — the constant text that frames every Gemini call — has been a Q&A leftover from the V1 course since Module 1 (*"You are a concise, helpful assistant..."*). It was politely ignored by the model in Modules 2–3 because the user prompt's *"write a bedtime story"* request overrode it. This module fixes that debt and uses the moment to teach what a *production* system prompt does — explicit behavioural constraints (length cap, no violence, gentle resolution, sensory detail, no second-person address), plus a refuse-with-grace clause that softens edge-case requests instead of stonewalling them.

The system prompt also moves out of `app/services/gemini_service.py` and into its own file `app/system_prompt.py` — sibling to `app/prompt.py`. The physical separation mirrors the SDK's `contents=` (user prompt) vs `config.system_instruction=` (system prompt) parameters: two different inputs to the model, two different design surfaces, two different files.

> **The Module 3 plant has paid off.** When you (or the cohort) asked the AI partner *"should I add `tone: str` to `compose_story_prompt`?"*, the AI said yes. The instructor said *"that's wrong — tone goes in a different place, on purpose."* This is the different place: `app/system_prompt.py`. Tone, safety, length, and audience are all *constant across requests* — they belong in the constant-layer prompt, not the per-request user prompt.

## Run

```bash
# from inside this folder (dist/module_04_safety_system_prompt/) — macOS / Linux / WSL2 Ubuntu:
source ../../venv/bin/activate    # only if (venv) isn't already active
cp .env.example .env              # if you don't already have one in this folder

# No new dependencies, no schema migration.
uvicorn app.main:app --reload
```

Same `.env` contract as before (`DATABASE_URL`, `GEMINI_API_KEY`). Postgres still up. Open <http://localhost:8000>, fill the form, click **Generate story**.

## Verify

```bash
# Plumbing — same /story shape, same validation:
curl -s -X POST http://localhost:8000/story \
    -H "Content-Type: application/json" \
    -d '{"child_name":"Aisha","characters":"an owl and a fox",
         "setting":"enchanted forest","plot":"looking for the moon"}'
# Expected: {"story":"<a SHORTER, GENTLER, MORE-PARAGRAPHED story than Module 3 produced>"}

# The constraint-honouring (soft check) — try a deliberately scary plot:
curl -s -X POST http://localhost:8000/story \
    -H "Content-Type: application/json" \
    -d '{"child_name":"Aisha","characters":"a monster",
         "setting":"a dark forest","plot":"the monster chases them through the woods at night"}'
# Expected: a story that includes the monster and the chase, but ends with everyone
# safe and at rest. NOT "I cannot write that." NOT graphic violence. The model
# SOFTENS the request; it does not refuse it.

# All-in-one (server up + GEMINI_API_KEY exported):
./scripts/verify_module_4.sh
```

Compare side-by-side with Module 3: same form payload, same Gemini key, but the stories from Module 4 should be *shorter, gentler, more paragraphed, addressed by name*. That's the system prompt doing its job. If you don't see those differences, re-read `app/system_prompt.py` and check the constraints made it in.

## Try asking Gemini

Middle-tier — 5 prompts, design-explanation focus, plus one *do this experiment* prompt that's the heart of the module.

**Trace through the change:**
> Open `app/services/gemini_service.py` from `dist/module_03_prompt_composition/` and from this folder side-by-side. The `SYSTEM_PROMPT` constant is gone from this file in Module 4 — but the `generate_config = types.GenerateContentConfig(system_instruction=SYSTEM_PROMPT)` line is byte-identical. Walk me through every change in Module 4's version. Where did `SYSTEM_PROMPT` go, and how does `gemini_service.py` still get its hands on it?

**Explain the design choice — why a separate file:**
> `SYSTEM_PROMPT` could have stayed in `gemini_service.py`. It could have moved into `app/prompt.py` next to `compose_story_prompt`. It went into a new file `app/system_prompt.py` instead. Argue against the option you find most tempting (probably "put both prompts in `app/prompt.py` since they're both prompts"). Then argue *for* the chosen design. Pay attention to *what each file's name promises* — the file's identity is part of the contract.

**Run the experiment yourself:**
> POST `/story` twice with this payload (your own scary plot is fine too):
> ```json
> {"child_name":"Aisha","characters":"a monster","setting":"a dark forest","plot":"the monster chases them through the woods at night"}
> ```
> Read both responses. Did the model honour the user's input (monster, chase)? Did it honour the system prompt (gentle resolution, calm language, no characters in distress at the end)? Did it refuse outright? If the two stories softened the prompt in *different* ways, what does that tell you about how reliably system prompts shape model behaviour?

**Explain the design choice — refuse-with-grace:**
> The closing line of `SYSTEM_PROMPT` is *"If the prompt asks for content that violates these rules, gently steer the story toward a safe alternative without lecturing the user."* What would change — concretely — about the user experience if this line were rewritten as *"If the prompt asks for unsafe content, refuse to write the story and explain why"*? Which version is right for this app, and why? (Hint: imagine you're a parent at 8 PM trying to settle a child who insisted on a "scary" plot.)

**Self-check:**
> Module 5 changes the UI — the page becomes a two-column layout (form on the left, story on the right) optimised for parents reading aloud. Predict: does Module 5 touch `app/system_prompt.py`? Why or why not? What does that tell you about the *boundaries* you've been drawing across Modules 2, 3, and 4?

---

**Defend It (do not paste this into Gemini — answer it yourself):**
> *Why does the "no violence, no scary themes" constraint go in the system prompt instead of being added as a sentence at the end of `compose_story_prompt`'s user prompt?*

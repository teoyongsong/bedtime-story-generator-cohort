# Module 5 — Update the UI for parents reading aloud

**Single fundamental:** UI structure matches the user's actual mental model.

Backend bytes don't move in this module. The whole change is in `app/templates/index.html` and `app/static/style.css`. The form moves to a left column, the story moves to a right column. The story body becomes serif at a generous size and line-height, on a soft cream pane bordered to read as "the page." When a story is active, the form pane dims to 0.6 opacity so the story is the visual focus — but the form is one hover or focus away from full strength when the parent wants to generate another story. On phones (≤700px) the layout collapses to a single column; the typography compresses; the pane padding shrinks.

> **What's not in Module 5.** No "Past stories" panel. Module 6 will add it and will redesign the layout when it does. Module 5 is the cleanest possible two-column shape, with no anticipation.

## Run

```bash
# from inside this folder (dist/module_05_story_ui/) — macOS / Linux / WSL2 Ubuntu:
source ../../venv/bin/activate    # only if (venv) isn't already active
cp .env.example .env              # if you don't already have one in this folder
uvicorn app.main:app --reload
```

Same `.env` contract as before (`DATABASE_URL`, `GEMINI_API_KEY`). Open <http://localhost:8000>.

## Verify

```bash
# Backend regression — /story unchanged:
curl -s -X POST http://localhost:8000/story -H "Content-Type: application/json" \
    -d '{"child_name":"Aisha","characters":"an owl and a fox",
         "setting":"enchanted forest","plot":"looking for the moon"}'
# Expected: {"story":"<a story>"}

# All-in-one (server up + GEMINI_API_KEY exported):
./scripts/verify_module_5.sh
```

Open the page in a browser. Fill the form. Click Generate. Watch the form pane dim and the story render on the cream pane in serif. Then resize the browser narrower than 700px — the layout stacks for phone reading.

## Try asking Gemini

Middle tier — 4 prompts, design-explanation focus.

**Trace through the change:**
> Open `app/templates/index.html` and `app/static/style.css` from `dist/module_04_safety_system_prompt/` and from this folder side-by-side. List every structural change to the HTML and every CSS decision in the new stylesheet. For each, ask: what user behaviour is this change trying to support?

**Explain the design choice — serif vs sans-serif:**
> The story body is `font-family: Georgia, "Iowan Old Style", serif`. The form labels and inputs are system-ui sans-serif. Two type families on one page. Argue: when does a single page benefit from two type families, and when does it just look messy? What does this *specific* split accomplish that one family alone wouldn't?

**Explain the design choice — `max-width: 38ch`:**
> The story is constrained to roughly 38 characters per line. Open the running app, generate a story, and try resizing the story-pane wider than the constraint allows. The story stays at 38ch even when the pane gets bigger. Why? What would change about the read-aloud experience if the line length were 80ch instead?

**Self-check before Module 6:**
> Module 6 introduces persistence (a `stories` table) and a `GET /stories?child_name=...` endpoint, plus a UI panel that shows recent saved stories for a child. Predict: does Module 6 redesign Module 5's two-column layout? Where does the new panel go — third column? Stacked above? Stacked below? Reading the doctrine and Module 5's "what's not in Module 5" callout, predict which option Module 6 takes and why.

---

**Defend It (do not paste this into Gemini — answer it yourself):**
> *Why does the form pane fade to opacity 0.6 when a story is active, instead of disappearing entirely or staying at full opacity?*

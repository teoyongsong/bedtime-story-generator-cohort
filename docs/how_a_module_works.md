# How a Module Works

You did the FastAPI Local LLM Question Log course. You know the per-module rhythm — `cd dist/module_NN_<slug>`, activate venv, run uvicorn, read the changed files, ask Gemini, answer Defend-It, move on. **The same rhythm carries through Modules 0–6 of this course.** This page maps where the rhythm stays the same, where it picks up a conversion-course overlay, and — most importantly — where **Module 7 breaks the rhythm entirely**.

Open it once before Module 1. Refer back when something feels off, especially when you arrive at Module 7.

---

## The conversion-course overlay

Bedtime is a conversion course. Module 0 is **the V1 final state** of the prior course, byte-identical. Modules 1–7 *transform* that V1 into a children's bedtime-story generator that calls Gemini and deploys to Vercel + Render.

**For every module past 0, the lesson is in BOTH halves of the conversion:**

- **What's removed** — and why it was right for V1, but not here. (E.g. Module 1 deletes the entire `ollama_service.py` file; Module 2 deletes three Pydantic Q&A classes and the `/history` endpoint; Module 5 deletes the single-column layout.)
- **What's added** — and why it's right here. (E.g. Module 1 adds the `google-genai` SDK call; Module 2 adds the `StoryRequest` schema and the `/story` endpoint; Module 5 adds the two-column read-aloud layout.)

When you read a module's changed files, open the **previous** module's matching file side-by-side. The deletions are as important as the additions. Sometimes more.

---

## The 8-beat rhythm — Modules 0 through 6

Same shape across these seven modules. By Module 2 you'll be doing it from muscle memory.

1. **`cd` into the module folder** — `cd dist/module_NN_<slug>/` from the cohort repo root. (E.g. `cd dist/module_03_prompt_composition/`.)
2. **Activate the shared venv** — `source ../../venv/bin/activate` (only if `(venv)` isn't already in your prompt). Same command on macOS, Linux, and WSL2 Ubuntu.
3. **Copy `.env.example` to `.env`** — `cp .env.example .env`. Required per dist folder because each is self-contained. Skipping this is the #1 source of `KeyError: '<ENV_VAR>'` at uvicorn startup — V1's loud-fail discipline working correctly, not a bug.
4. **Run it** — `uvicorn app.main:app --reload`. Open <http://localhost:8000>.
5. **Use the page** — actually click the button, fill the form, generate a story, watch the uvicorn log.
6. **Read the changed files alongside the previous module's** — the README points at which files changed. Open the matching file from `dist/module_(NN-1)_<slug>/` side-by-side. **Read the deletions first;** then the additions.
7. **Ask Gemini the "Try asking Gemini" prompts** — paste them into the Gemini chat panel in Antigravity. Read what it says. Ask follow-ups in your own words.
8. **Answer the Defend-It at the bottom of the README** — **do not paste this into Gemini.** Reasoning through it yourself is the only step that proves you actually understand the module.

**Optional 9th — Tweak.** Each README suggests one small change (change the safety constraints, swap the layout colours, run a different SQL query). Hands-on learners gain a lot here. Not required; recommended if the module clicked quickly and there's time before the next.

### What stays the same — what varies (Modules 0–6)

| | Same in every module | Varies per module |
|---|---|---|
| **`cd` target** | `dist/module_NN_<slug>/` | The `NN` and `<slug>` |
| **venv command** | `source ../../venv/bin/activate` | Never changes |
| **`.env` setup** | `cp .env.example .env` | Module 0: Ollama vars. Modules 1+: `GEMINI_API_KEY`. |
| **Run command** | `uvicorn app.main:app --reload` | Never changes (until Module 7) |
| **Module 6 migration** | One-off — `psql "$DATABASE_URL" -f sql/002_create_stories.sql` before uvicorn | Only Module 6 has it |
| **File-reading shape** | "Open previous + current side-by-side; deletions first" | Which files vary per module |
| **Defend-It** | One question at the bottom; do NOT paste into Gemini | Question text varies |

After Module 2 you'll stop reading the rhythm — you'll do it from muscle memory. That's the point.

---

## ⭐ Module 7 breaks the rhythm

Module 7 deploys to the internet. **Production hosts have different runtime semantics than your laptop.** The single-terminal `uvicorn ... --reload` shape that carried Modules 0–6 doesn't work in Module 7. Four things change.

### 1. Local dev is now two terminals

The backend (FastAPI on `:8000`) and the frontend (static HTML on `:5173`) become two separate processes that you run in parallel:

```bash
# Terminal 1 — backend:
cd dist/module_07_deploy_vercel
source ../../venv/bin/activate    # if needed
cp .env.example .env              # if needed
uvicorn app.main:app --reload

# Terminal 2 — frontend (any unused port works; 5173 is the convention):
cd dist/module_07_deploy_vercel
source ../../venv/bin/activate    # if needed (the venv isn't required for python -m http.server, but it keeps your terminal consistent)
python -m http.server 5173 --directory frontend
```

Open <http://localhost:5173>, NOT `:8000`. The frontend page makes a cross-origin `fetch()` to `localhost:8000`; the backend's CORS middleware lets it through. Both servers running = working app.

### 2. `BACKEND_URL` is a hardcoded JS constant you edit per deploy

`frontend/script.js` ships with `const BACKEND_URL = "http://localhost:8000";` for local dev. When you deploy, you edit that single line to your real Render service URL, commit, and push — Vercel auto-redeploys with the new URL baked into the static JS.

**uvicorn does NOT restart when you save `frontend/script.js`.** uvicorn watches `app/`, not `frontend/`. After editing `script.js` locally, just refresh the browser; uvicorn doesn't need to know.

### 3. The deploy itself is a 5-phase procedure (not a Run command)

Modules 0–6's "run it and read the README" pattern doesn't apply. Module 7's deploy is:

- **Phase 0** — Push your bedtime app to YOUR GitHub (so Render and Vercel can read it from a repo you control — the instructor's cohort repo lives on the instructor's GitHub, not yours).
- **Phase 1** — Render Blueprint deploy (backend + managed Postgres provisioned together from `render.yaml`; `GEMINI_API_KEY` set in the Render dashboard, never committed).
- **Phase 2** — Vercel project import (frontend deploys as static files from `vercel.json`, no build step).
- **Phase 3** — Wire frontend → backend (edit `BACKEND_URL` in `script.js`, commit, push, Vercel auto-redeploys).
- **Phase 4** — Verify on a phone (open the Vercel URL on a non-laptop device, generate a story, confirm it lands in Render's Postgres).

The **deploy guide PDF your instructor sent** walks every click. Open it before you start Module 7's hands-on work — don't try to navigate the Render and Vercel dashboards from memory.

### 4. Verification moves off your laptop

Through Module 6, "verify" meant `./scripts/verify_module_N.sh` against `localhost:8000`. In Module 7, verify means *"open the Vercel URL on your phone, on a different network from your laptop's, generate a story, confirm it actually works for someone who isn't you."* The internet is the test environment now.

---

## The small steps you stop noticing

Invariants you may have internalised from FastAPI. Spelled out in case any aren't yet muscle memory:

- **`(venv)` in your prompt = venv is active.** No `(venv)` = no venv. Glance at the prompt before pasting any command.
- **Every fresh terminal needs the venv re-activated.** New tab does NOT carry it across. The symptom is `bash: uvicorn: command not found` — that's the signal. Re-activate from inside the dist folder.
- **`cd` location matters.** You should be inside `dist/module_NN_<slug>/` when running module commands, NOT at the cohort root. Your prompt should end in `module_NN_<slug>$`. Running `uvicorn app.main:app` from the cohort root will start a *different* app — the Module 7 deploy-shape backend at the root, which has no `/` route and returns 404 on the browser.
- **The cohort repo never changes module to module.** You don't re-clone, you don't pull, you don't switch branches. Just `cd` into the next folder.

---

## When uvicorn restarts itself, and when you restart it

`uvicorn ... --reload` watches files inside `app/`. When you save a file there, uvicorn auto-restarts within a second. You'll see `Detected change in 'app/main.py'. Reloading...` in the log. **This is the normal case for every code edit in Modules 1–6** — just save the file and watch the uvicorn log.

You need to restart uvicorn manually (`Ctrl+C`, then re-run) only when:

- **You added a new dependency** with `pip install` — the running uvicorn has the old set of packages loaded and won't see the new one until it restarts.
- **uvicorn is stuck in a failed-startup state** from an earlier error you've since fixed.
- **You edited `frontend/script.js` (Module 7 only)** — uvicorn doesn't watch `frontend/`. Just refresh the browser; no uvicorn restart needed, despite the file change.

If you find yourself `Ctrl+C`-ing after every edit, you're working harder than the tool needs.

---

## Common confusions

| Symptom | What's happening | One-line fix |
|---|---|---|
| `bash: uvicorn: command not found` | Fresh terminal, venv not active | `source ../../venv/bin/activate` from inside the dist folder |
| `KeyError: 'OLLAMA_BASE_URL'` or `'GEMINI_API_KEY'` at uvicorn startup | `.env` is missing in this dist folder | `cp .env.example .env` in this folder, then re-run uvicorn |
| `404 Not Found` on `GET /` after starting uvicorn | You started uvicorn from the cohort root, not from a dist folder | `cd dist/module_NN_<slug>` first, then re-start uvicorn |
| `address already in use` when starting uvicorn | Another uvicorn is still running in some other terminal | Find that terminal and `Ctrl+C`. Can't find it? `lsof -i :8000` (macOS / WSL2 Ubuntu) shows the process |
| `psql: ... FATAL: database "<your-username>" does not exist` | `$DATABASE_URL` empty in this shell — `.env` loads into Python's `os.environ`, not your terminal | `export DATABASE_URL=postgresql://postgres:postgres@localhost:5432/llm_question_log` (or set it persistently in `~/.zshrc` on macOS or `~/.bashrc` on WSL2 Ubuntu) |
| Browser shows old output after you edit a file in `app/` | Either uvicorn didn't auto-reload, or you edited the wrong file | Check uvicorn log for a `Reloading...` line. Check your `cd` location matches the folder of the file you edited. |
| Module 7 only: editing `frontend/script.js` doesn't refresh anything | uvicorn doesn't watch `frontend/` — only `app/` | Refresh the browser manually. No uvicorn restart needed. |

For **WSL2-specific friction** (Antigravity opens to Windows paths instead of WSL2, `sudo` password no visible feedback, `/mnt/c/` slowness, `gh auth login` browser doesn't open): paste the symptom into the Gemini chat panel — `AGENTS.md` §4 *Linux / WSL2 on Windows* has nine WSL2-bridge reducers Gemini surfaces automatically.

For anything else: paste the failing line into the Gemini chat panel. `AGENTS.md` is loaded at the cohort root and Gemini knows the course's friction points.

---

## Where to go for deeper detail

- **The exact `Run` commands and the "Try asking Gemini" prompts for the module you're on** — that module's README at `dist/module_NN_<slug>/README.md`.
- **The single-fundamental map across all 8 modules** — the [cohort README](../README.md) Module Map section.
- **How Gemini is coached to behave in this course** — [`AGENTS.md`](../AGENTS.md) at the cohort root, especially §4 *Friction reduction*.
- **The full narrative walkthrough, module by module** — the crash-course PDF your instructor sent with the course materials.
- **The Module 7 deploy click-by-click** — the deploy-guide PDF your instructor sent. Open it before you start Module 7's deploy phases.
- **Publishing your V1 at the end** — [`docs/publish_your_work.md`](publish_your_work.md).

---

*This page is the map. The modules are the territory. Module 7 is where the map changes — re-read this page when you arrive there.*

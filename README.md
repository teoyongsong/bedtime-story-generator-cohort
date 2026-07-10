# Bedtime Story Generator — cohort repo

A staged, hands-on **conversion course** that turns a working FastAPI Q&A app into a children's bedtime-story generator that calls Google's Gemini API and deploys to Vercel + Render — *one fundamental at a time, across eight modules.*

> **License:** [PolyForm Noncommercial 1.0.0](LICENSE). You may use this code freely for personal learning and non-commercial educational use (and you can publish your forked deploy as a portfolio piece per `docs/publish_your_work.md`). You may not use it as the curriculum for a fee-charging course. See [NOTICE.md](NOTICE.md) for plain-English allowed/not-allowed lists.

This repo is your starting point. You'll work through it module-by-module during the live session and on your own afterwards. By the end, you'll have an app on the internet — Vercel-hosted frontend, Render-hosted backend, managed Postgres — that a parent on a different network can use to generate a bedtime story for their child. You'll publish the result to your own GitHub as a portfolio piece.

## Welcome

The course is the V2 of the SCTP **Local LLM Question Log** course. **You're expected to have already shipped that V1.** This curriculum builds on the V1 mental models — server-as-receptionist, system prompt as a list of messages, env-var loud-fail — and teaches you to *transfer* them to a different domain (children's bedtime stories) while replacing key dependencies (Ollama → Gemini API, single-textarea UI → structured form, local dev → public deploy).

The course is for adult mid-career learners. You don't need to be an expert coder — you need to be willing to read code carefully, ask good questions, and build a mental model of how the pieces fit together. The AI partner in your IDE (Gemini in Antigravity) is configured to coach, not to do the work for you.

> **Conversion course, not build-from-scratch.** Module 0 is the **V1 final state** of the prior course, copied byte-identical. Every later module *transforms* it — deletes some code, adds some code, ends with a still-working app. **For every module past 0, expect to read about both halves: what's removed and why, what's added and why.** The transformation itself is the lesson.

## Before class — pre-flight checklist

**Do this once, at home, before the live session.** Allow ~30 minutes if your V1 stack is still intact, ~45 minutes if you need to reinstall Postgres or Ollama. **Installs do not scale on a 40-person Zoom call** — anyone who arrives without these working will spend the live block catching up instead of learning.

The five things you need:

| # | What | Why |
|---|---|---|
| 1 | **Python 3.11+** | The web server runtime. Carries from V1. |
| 2 | **Postgres 17** | Where stories will be persisted (Module 6 onwards). The V1 `interactions` table carries through Modules 0–5. |
| 3 | **Ollama** with the `llama3.2` model pulled (~2 GB) | Module 0 only — the V1 baseline still uses it. Module 1 replaces it with the Gemini API; you can stop Ollama from then on. |
| 4 | **[Google Antigravity](https://antigravity.google)** signed in with Gemini enabled | Your IDE for the course. Gemini is your in-editor AI partner. |
| 5 | **Google AI Studio API key** for Gemini (free tier) — get one at <https://aistudio.google.com/apikey> | The hosted LLM your app will call from Module 1 onwards. Save the key somewhere only you can see it. |

For **Module 7** (the closing deploy module) you'll also need:
- A free **Render** account (<https://render.com>)
- A free **Vercel** account (<https://vercel.com>)

You don't need either of these for the first six modules. Sign up the morning of Module 7's session, or the night before — it takes ~2 minutes each.

The pre-flight install above is what you need. Don't skip the database-creation and schema-apply steps — those produce the most common Day-1 failures.

### Clone this repo

```bash
git clone https://github.com/SwarupSG/bedtime-story-generator-cohort.git
cd bedtime-story-generator-cohort
```
(macOS / Linux / WSL2 Ubuntu — same commands.)

> **Windows learners:** do this *inside an Ubuntu terminal* (your WSL2 environment from the FastAPI course), NOT native PowerShell. Clone into `~/code/` (Ubuntu's native filesystem) — not `/mnt/c/...`. The cross-filesystem bridge is 10–50× slower for `pip install` and `psycopg[binary]`. If you accidentally clone into `/mnt/c/`, just re-clone into `~/code/`.

### Set up the shared venv (once per machine)

The shared `venv/` lives at the cohort repo root. Every dist folder activates it via `../../venv/bin/activate`.

```bash
python3 -m venv venv
source venv/bin/activate
```
(macOS / Linux / WSL2 Ubuntu — same commands. The `(venv)` prefix in your prompt is the visual confirmation.)

Then install **all** course dependencies in one shot. The root `requirements.txt` is the union of every module's deps:

```bash
pip install -r requirements.txt
```

That's it for Python packages — you won't `pip install` again for the rest of the course.

### Prove your services are running (the "am I ready?" check)

Binary on PATH ≠ service running. From the cohort repo root with the venv active:

```bash
./scripts/verify_setup.sh
```
(macOS / Linux / WSL2 Ubuntu — same command. Run from inside your Ubuntu terminal for WSL2.)

Every check green, ending with *"All checks passed. You're ready for Module 1."* means you're ready. Each ✗ line tells you the exact one-line command to fix it.

**If anything fails:** open Antigravity, paste the failing ✗ line into the Gemini chat panel along with what you've already tried. Gemini will coach you to the fix. The live block's instructor is your last resort, not your first.

## The 5-step Class Flow (same pattern in every module)

Every module's session follows this same sequence. Adult learners find it easier when there's one shape:

1. **`cd` into the module's folder** — `dist/module_NN_<slug>/`. Open it in Antigravity.
2. **Run** it — paste the commands from the module's `README.md` *Run* section into your terminal. See the working app first.
3. **Read** the deletions and additions. **For every module past 0, the lesson is in BOTH halves.** Open the previous module's folder side-by-side in your editor — see what disappeared, see what took its place.
4. **Ask Gemini** to explain it — paste any of the *"Try asking Gemini"* prompts from the module's README into the Gemini chat panel. Read what Gemini says. Ask follow-ups.
5. **Answer the Defend-It question** at the bottom yourself before moving on. *Don't paste the Defend-It into Gemini.* Reasoning through it yourself is the assessment.

Optional 6th step for hands-on learners: **tweak one thing** the module's README suggests (e.g. change the safety constraints in Module 4's system prompt, change the layout colours in Module 5).

## How to use Gemini in Antigravity

Two surfaces, both available all the time:

- **Chat panel** (right side of Antigravity) — paste *"Try asking Gemini"* prompts from each module's README. Gemini explains the code Socratically: it'll usually ask you what you *think* before delivering the answer. Ask follow-ups freely. The Defend-It question at the bottom of every module is the one prompt you should NOT paste — that's the assessment.
- **Inline autocomplete** — as you type code, Gemini suggests completions. Suggestions stay scoped to whichever `dist/module_NN_*/` folder you have open, so you don't get Module 6's Postgres code while you're typing in Module 2.

Why does Gemini behave this way? Because [`AGENTS.md`](AGENTS.md) at the root of this repo is loaded into Gemini's context whenever Antigravity opens the workspace. That file is Gemini's "system prompt" for this course. (Cursor and Claude Code also read `AGENTS.md` — same rules, any IDE.) **Module 4 is when you'll write the bedtime story app's own `system_prompt.py` for Gemini-the-LLM** — the same shape of file, just for a different audience. The deepest moment in the course is when you realise you've been living inside one all along.

## Module map

| Folder | Single fundamental |
|---|---|
| [`dist/module_00_baseline/`](dist/module_00_baseline/) | Anchor your starting point — the V1 final state, byte-identical |
| [`dist/module_01_swap_to_gemini/`](dist/module_01_swap_to_gemini/) | A hosted LLM via SDK is *less* code than a hand-rolled HTTP client |
| [`dist/module_02_form_input/`](dist/module_02_form_input/) | Naming follows the domain — schema, endpoint, fields |
| [`dist/module_03_prompt_composition/`](dist/module_03_prompt_composition/) | Prompt composition is itself a piece of code with rules and care |
| [`dist/module_04_safety_system_prompt/`](dist/module_04_safety_system_prompt/) | Production system prompts include safety constraints, not just style |
| [`dist/module_05_story_ui/`](dist/module_05_story_ui/) | UI structure matches the user's actual mental model |
| [`dist/module_06_story_library/`](dist/module_06_story_library/) | Persistence + click-to-rehear — the schema fits what the user re-uses |
| [`dist/module_07_deploy_vercel/`](dist/module_07_deploy_vercel/) | Production deploys split static (CDN) from long-running (server) — without re-learning your stack |

The V1 final code lives at the cohort root (`app/`, `frontend/`) — it's the same as `dist/module_07_deploy_vercel/`. **Don't run `uvicorn app.main:app --reload` from the cohort root** — the root's `app/` is Module 7's deploy-shape backend with no `/` route, so you'll see `404 Not Found`. Always `cd dist/module_NN_<slug>` first.

## Publish your work

At the end of Module 7 you have a complete, working V1 — *deployed*. The closing step of the course is to publish your version to your own GitHub as a portfolio piece — your *"I built this"* you can show to recruiters and managers, with a live demo URL they can click.

The walk-through is in **[`docs/publish_your_work.md`](docs/publish_your_work.md)** — ~30–45 minutes, copy-paste-ready commands for both macOS and Windows, a personal-README template with your real Vercel + Render URLs, a security checklist (no leaked API keys or database passwords), and a list of meaningful next-step extensions (streaming, audio narration, multi-child accounts, themed bedtime modes, custom domain).

## Where to get help

- **If the per-module rhythm feels uncertain or Module 7 catches you off-guard:** [`docs/how_a_module_works.md`](docs/how_a_module_works.md) — the per-module rhythm map, including the conversion-course overlay (what's removed + what's added) and an explicit *"Module 7 breaks the rhythm"* section preparing you for the two-terminal local dev + 5-phase deploy procedure.
- **In the live session:** ask Gemini first using a module's *"Try asking Gemini"* prompt. If you're still stuck after 10 minutes, post a screenshot of the failing command in the cohort's async help channel and stay on the call.
- **Between sessions:** async help channel + your instructor's office hours.
- **If `verify_setup.sh` fails:** the script prints the exact one-line fix on the failing line. Paste it, re-run.
- **If `psql` errors with `FATAL: database "<your-username>" does not exist`** (you'll first see this in Module 6 when the migration step runs): `$DATABASE_URL` isn't set in your *shell* — Python's `.env` loads into the Python process, not your terminal. Quick fix: `export DATABASE_URL=postgresql://postgres:postgres@localhost:5432/llm_question_log` and re-run. Each per-module README reminds you when it's needed.
- **If Module 7's deploy returns `FUNCTION_INVOCATION_FAILED`:** Vercel auto-detected the Python backend instead of treating it as a static-only deploy. The fix is in the `.vercelignore` file at the repo root — make sure it ships when you deploy.


# Publish Your Work — Bedtime Story Generator

You finished the course. You have a working V1 — *Browser → Vercel CDN → Render FastAPI → Gemini API + Render Postgres* — end-to-end, every line of which you can explain. Now publish it to your own GitHub as a portfolio piece, and link to your live deploy.

This is the closing exercise of the course. Allow about **30–45 minutes** if it's your first GitHub push, faster if you've done one before. The deploy step you already did in Module 7 means the *"works on the internet"* part is done — this exercise is about packaging it as something a recruiter, a teammate, or a future-you can read in two minutes and understand.

## Why publish

You built something real. It's small, but it's serious — **a child-safety-aware bedtime story generator with persistent re-hearing, deployed across a split static + long-running stack with proper CORS handling, env-var loud-fail discipline, and a database whose schema was designed around the actual user behaviour** (parent re-reads yesterday's story to a tired child). Most "I learned to code" portfolio projects are tutorial clones with no ownership. Yours isn't. **You can defend every line.** That's what hiring managers want to see, and the only way to prove you have it is to put the code somewhere they can read it — and the deploy URL somewhere they can click it.

## What to publish

The Module 7 final state — the contents of your `dist/module_07_deploy_vercel/` folder, OR (better) your already-edited fork that's running on Render + Vercel right now. That's the working app.

- You **don't** publish the whole cohort repo (it's not yours; you cloned it).
- You **don't** publish all 8 `dist/` checkpoints (a portfolio piece is one app, not a course archive).
- You publish the one thing you built — Module 7's deploy-shape app, with your real Render URL hardcoded into `frontend/script.js`'s `BACKEND_URL`.

**Your live deploy stays where it is.** You don't redeploy. The Render service and Vercel project you already provisioned during Module 7 are *your* artifacts on the public internet. The portfolio repo points at them; recruiters click the live URL and see your actual app.

If you tweaked anything during the course — adjusted the system prompt's tone, changed the cream-pane colour, added a "favourite story" button, added a different model variant — keep your changes. They're proof of ownership.

## Pre-publish checklist

Before pushing anything to a public repo, confirm:

- [ ] **No secrets.** `.env` is in `.gitignore`. Open `.gitignore` and confirm `.env` is on its own line. Run `git ls-files | grep -E "\.env$"` from inside the folder you're about to publish — if anything other than `.env.example` shows, stop and fix.
- [ ] **No hard-coded API keys.** Search your code: `grep -r "GEMINI_API_KEY" app/ frontend/` should only show *uses* of the env var (`os.environ["GEMINI_API_KEY"]`), never a real key value.
- [ ] **No leaked database URLs.** `grep -r "@.*\.onrender\.com" app/ frontend/` should return nothing. Render service URLs (`bedtime-story-api-XXXX.onrender.com`) are fine to publish; **External Database URLs** (containing the password) are not. The frontend's `BACKEND_URL` is the service URL — that's the one that ships.
- [ ] **The deployed app works.** Open your Vercel URL on your phone or in an incognito tab. Generate a story end-to-end. If it fails, fix the deploy before publishing the repo (a portfolio link to a broken app is worse than no link).
- [ ] **A personal README.** This is your portfolio piece's front page; it should explain what the app is, the live URL, how to run locally, and what you learned building it. Template below.
- [ ] **Decide visibility.** Public is the right default for a portfolio piece (recruiters need to read it). If you have a reason to start private, that's fine; flip later.

## Step-by-step

### 1. Move the folder you're publishing OUT of the cohort clone

```bash
cp -R <cohort-clone>/dist/module_07_deploy_vercel ~/bedtime-story-generator
cd ~/bedtime-story-generator
```
(macOS / Linux / WSL2 Ubuntu — same commands. On WSL2, `~/bedtime-story-generator` is `/home/<your-username>/bedtime-story-generator` inside Ubuntu — NOT `/mnt/c/`.)

The folder name (`bedtime-story-generator` above) becomes your repo name later. Pick a name that signals *"this is mine"* — `bedtime-story-generator-aisha`, `bedtime-stories-app`, `lily-bedtime-app`, whatever fits. Avoid names that imply you wrote a generic library (`bedtime-story-lib`).

Confirm the folder has these files/dirs:

```
app/
frontend/
sql/
scripts/
.env.example
.gitignore
.vercelignore
Procfile
render.yaml
requirements.txt
vercel.json
README.md          (the per-module README from the course — you'll replace this)
```

If anything is missing, you may have copied the wrong folder.

### 2. Replace the README with your own

The current `README.md` is the course's per-module README. Replace it with your portfolio version. Template — fill in the `<...>` placeholders:

```markdown
# <YOUR-APP-NAME>

A child-safety-aware bedtime story generator. A parent enters their child's name, characters, a setting, and a one-line plot; the app calls Google's Gemini through a hosted API, returns a short bedtime story formatted for reading aloud, and persists it so the child can re-hear yesterday's story without re-generating it. Built as the capstone of the SCTP **Bedtime Story Generator** conversion course.

## Live demo

- **Frontend:** <https://your-vercel-url.vercel.app>
- **Backend health:** <https://your-render-url.onrender.com/healthz> *(returns `{"postgres":true}`)*

> **Note on cold starts.** The backend runs on Render's free tier and spins down after 15 minutes of no traffic. The first request after a sleep takes ~30 seconds while it warms up; subsequent requests are sub-second. That's free-tier behaviour, not a bug.

## What it does

- Four-field form (child name, characters, setting, plot) → calm, child-safe bedtime story (≤5 paragraphs, addresses the child by name, no violence, gentle resolution).
- Stories are persisted to Postgres against the child's name. Click any saved story in the *"Past stories"* panel to re-hear it without paying for a new Gemini call.
- Production deploy: Vercel CDN for the static frontend, Render for the long-running FastAPI backend with managed Postgres. CORS configured to allow cross-origin requests.
- Loud-fail config — missing `GEMINI_API_KEY` or `DATABASE_URL` refuses to start, never silently runs broken.

## Stack

- **Python 3.11 + FastAPI** — backend HTTP API (3 endpoints: `POST /story`, `GET /stories`, `GET /healthz`).
- **Google Gemini API (`gemini-2.5-flash-lite`)** — hosted LLM for story generation, called via the `google-genai` SDK.
- **Postgres + psycopg 3** — managed Postgres on Render; one table (`stories`) with a composite index on `(child_name, created_at DESC)`.
- **Plain HTML + CSS + vanilla JS** — no framework, no build step. Three static files served from Vercel.
- **Render + Vercel** — backend on Render (Blueprint deploy from `render.yaml`), frontend on Vercel (static deploy from `vercel.json`).

## Run it locally

Requires Python 3.11+, Postgres, and a free Google AI Studio API key (<https://aistudio.google.com/apikey>).

```bash
# 1. Setup
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 2. Configure
cp .env.example .env
# Edit .env: paste your real GEMINI_API_KEY; DATABASE_URL stays as the local default

# 3. Database
createdb llm_question_log
psql "$DATABASE_URL" -f sql/002_create_stories.sql

# 4. Run two terminals (the deploy split mirrors local dev):
# Terminal 1 — backend on :8000
uvicorn app.main:app --reload

# Terminal 2 — frontend on :5173
python -m http.server 5173 --directory frontend
```

Open <http://localhost:5173>. The frontend's `BACKEND_URL` is hardcoded to my Render production URL — for local testing against your own backend, edit that line in `frontend/script.js`.

## What I learned

*(One or two paragraphs in your own words. Concrete examples — pick the two or three that landed hardest for you. Drafts to start from:)*

- *"The schema names the domain, not the UI. Module 2 deleted V1's `interactions` table and three Pydantic classes when the app went from Q&A to bedtime stories — even though they were structurally similar — because the names lied about what was happening."*
- *"Production system prompts include safety constraints, not just style. The shift from V1's `'You are a concise, helpful assistant'` to a five-rule system prompt with a refuse-with-grace closing line was the moment the app started feeling like something for a real child, not a demo."*
- *"Storing the generated body alongside the inputs, not just the inputs, is the whole reason the click-to-rehear feature works. Re-generating from the same form fields gives a different story (LLMs are non-deterministic) and costs a Gemini call; storing the body is essentially-free disk for a feature the child actually wants."*
- *"The Vercel + Render split surfaced cross-origin handling without re-introducing serverless. Same uvicorn-as-receptionist mental model from V1, just on a different host."*

## What's next

*(Optional. Extensions you're considering — see "What to do next" at the bottom of the course's `docs/publish_your_work.md`.)*

---

🤖 Built with [Claude Code](https://claude.com/claude-code) and [Antigravity (Gemini)](https://antigravity.google) as AI partners during the SCTP Bedtime Story Generator course.
```

Save it as `README.md` in your new folder, replacing the existing file. **Edit the `<YOUR-APP-NAME>`, `<https://your-vercel-url.vercel.app>`, and `<https://your-render-url.onrender.com>` placeholders to your real values.** A README with placeholder text is worse than no README.

### 3. Remove the per-module course content

Two extra files to remove from your portfolio repo (they're course artifacts, not portfolio artifacts):

```bash
rm -f scripts/verify_module_7.sh
rm -rf .claude .cursor .vscode    # any IDE-specific cache that snuck in
```
(macOS / Linux / WSL2 Ubuntu — same commands.)

The verify scripts and `scripts/verify_setup.{sh,ps1}` are fine to keep — they're useful for anyone running your repo locally. But the `verify_module_7.sh` specifically references the curriculum's regression checks, which a recruiter looking at your portfolio doesn't need.

### 4. Fresh `git init`

You're publishing this folder as its own repo with no inherited history.

```bash
# Confirm you're in the right folder:
pwd
# Should print something ending in your-app-name, NOT bedtime-story-generator (cohort)

# Remove any existing .git/ that might be there from being inside the cohort clone:
rm -rf .git

# Fresh init
git init
git branch -M main
git add .
git status                             # eyeball — confirm no .env, no venv/, no __pycache__/
git commit -m "Initial commit — <YOUR-APP-NAME> V1"
```

### 5. Create the GitHub repo

Two paths — either works.

#### Option A — `gh` CLI (faster if you have it installed)

```bash
gh repo create <your-repo-name> \
  --public \
  --source=. \
  --remote=origin \
  --description "Child-safe bedtime story generator built on FastAPI + Gemini API + Vercel + Render — capstone of the SCTP Bedtime Story Generator course"

git push -u origin main
```

#### Option B — GitHub web UI

1. Go to <https://github.com/new>.
2. **Repository name:** `<your-repo-name>` (your choice).
3. **Description:** *"Child-safe bedtime story generator built on FastAPI + Gemini API + Vercel + Render — capstone of the SCTP Bedtime Story Generator course"*
4. **Visibility:** Public.
5. **Initialize this repository with:** leave **all three checkboxes unchecked**.
6. Click **Create repository**.

GitHub now shows you a "push an existing repository from the command line" snippet. Copy and run those three lines.

### 6. Confirm it's live

Open `https://github.com/<your-username>/<your-repo-name>` in your browser:

- Your README renders as the front page.
- The live demo links work (clicking them opens your Vercel URL and `/healthz` shows `{"postgres":true}`).
- The file tree shows the expected files.
- **No `.env` is visible** — confirm by looking. If you see `.env` in the file list, **immediately**:

```bash
git rm --cached .env
git commit -m "Remove accidentally committed .env"
git push
```

…and **rotate your `GEMINI_API_KEY`** at <https://aistudio.google.com/apikey> (delete the old key, generate a new one, paste the new one into Render's Environment tab). The old key may have been scraped by GitHub's secret-scanning crawlers between push and removal.

### 7. Optional polish (~10 extra minutes, recommended)

- **Add a screenshot.** Open your Vercel URL, generate a story (use a benign payload — `Aisha / a kind owl / an enchanted forest / looking for the moon`), screenshot the rendered page. Save as `screenshot.png` at the repo root. Reference from your README's *Live demo* section: `![Screenshot](screenshot.png)`.
- **Add GitHub topics.** On the repo page, click the gear icon next to *About*, add topics: `fastapi`, `gemini-api`, `vercel`, `render`, `bedtime-stories`, `python`, `postgres`, `llm`. Discoverable in GitHub search.
- **Pin it to your profile.** GitHub profile → *Customize your pins* → select this repo. Three pins matter; this should be one of them if you're early-career.
- **Add a tweet/post link** if you announce it on LinkedIn / Twitter / Bluesky. Put the post URL in the README's footer — recruiters who find you on LinkedIn want to find your code, and vice versa.

## What to do next

The V1 you built is the foundation, not the destination. Pick **one** of these to extend it (each is a meaningful next step, not a tutorial copy-along). Pick *one* — building one extension well is more impressive than starting three.

- **Streaming responses.** Replace the full-response `/story` with server-sent events that stream the story word-by-word as Gemini generates it. The frontend renders progressively. **Teaches:** `Response`-based streaming in FastAPI, the `text/event-stream` content type, browser-side `EventSource`. The user-visible payoff: *the story starts appearing in ~1 second instead of waiting 5 seconds for the whole thing.*

- **Audio narration.** After the story renders, call a text-to-speech API (Google Cloud TTS, ElevenLabs, OpenAI TTS) and offer a play button on the story-pane. **Teaches:** chained API calls, audio-blob handling in the browser, the cost-vs-magic trade-off (TTS is *expensive* per call — you'd cache the audio against the story's `id` in the same way Module 6 stored the body).

- **Multi-child accounts.** Replace the single `child_name` field with a "Pick a child" dropdown backed by a `children` table; each child has their own story library; parents can switch between children. **Teaches:** simple authentication boundaries, schema relationships, the YAGNI conversation about *"do we need real auth, or is a child-name dropdown enough for V2?"*

- **Themed bedtime modes.** Add a "calm / silly / adventurous" tone selector that changes the system prompt at request time. The system prompt becomes parameterised by tone. **Teaches:** prompt parameterisation, the boundary between user prompt (per-request) and system prompt (constant) — the *exact* tension Module 4 introduced — now resolved with a small explicit interface.

- **Re-deploy under your own domain.** Buy a domain (Cloudflare Registrar, Namecheap), point it at Vercel for the frontend and Render for the backend's API subdomain. **Teaches:** DNS records, custom domains in Vercel/Render, HTTPS certificate provisioning, and *why CORS gets simpler the moment your frontend and backend share an apex domain.*

Whichever you pick: **it's a new repo, not this one.** You're building a portfolio of small serious things, not one ever-growing megaproject. Each new repo is another *"I built this"* you can defend.

---

*Need help mid-publish? Ask Gemini in Antigravity — `AGENTS.md` still applies in your cloned cohort folder. Or post in the cohort async channel.*

# Module 7 — Deploy: Vercel frontend + Render backend (with managed Postgres)

**Single fundamental:** Production hosts have different runtime semantics than your laptop.

**This is the final V1 module.** When you finish it, your bedtime-story app is on the internet — Vercel-hosted frontend, Render-hosted backend, Render-managed Postgres — usable by any parent on any device.

The codebase splits into two: `frontend/` (what Vercel deploys — three static files) and `app/` (what Render runs — JSON API only, no HTML serving). The backend gains CORS middleware so the cross-origin browser-to-API requests succeed. Three small deploy-config files — `Procfile`, `render.yaml`, `vercel.json` — each owning one deploy concern. The `app/templates/` and `app/static/` directories are deleted (they'd be dead code in production); `jinja2` is dropped from requirements; the `/` HTML route on FastAPI is gone.

> **The architectural decision being demonstrated.** Vercel for the frontend (static), Render for the backend (long-running uvicorn) + managed Postgres. NOT Vercel-everything serverless. The PRD locked this in §3 — the V1 mental model carries unchanged into deploy. The Defend-It at the bottom of this README asks you to articulate why.

## Local development workflow (post-Module-7)

The "uvicorn serves everything" workflow from earlier modules is gone. Local dev now uses **two terminals**, both inside this dist folder:

```bash
# Terminal 1 — backend on :8000 (macOS / Linux / WSL2 Ubuntu — same commands):
cd dist/module_07_deploy_vercel    # only if not already here
source ../../venv/bin/activate     # only if (venv) isn't already active
cp .env.example .env               # if you don't already have one in this folder
uvicorn app.main:app --reload

# Terminal 2 — frontend on :5173 (any unused port works)
# Same cd + activate as above, then:
python -m http.server 5173 --directory frontend

# Browser: http://localhost:5173
```

The frontend's `BACKEND_URL` constant in `frontend/script.js` ships as `"http://localhost:8000"` for local dev — points at terminal 1. The CORS middleware on the backend lets the cross-origin request through. **For production deploy, you'll edit `BACKEND_URL` to your Render service URL — see the Deploy section below.**

## Deploy to production

> **This section is the in-context summary.** For click-by-click with screenshots, exact button labels, and the full common-gotchas table, keep `deploy_guide.pdf` (sent by your instructor during class) open while you work through Phases 0–4 below.

### 0. Push your bedtime app to YOUR GitHub (~5 minutes)

Render and Vercel deploy by **reading from a GitHub repo they have access to** — typically a repo in your own GitHub account. Your local cohort clone lives on the instructor's GitHub, not yours, so you push the code to your own GitHub first. Two clean paths — pick whichever feels natural:

- **Path A (simplest)** — fork the cohort repo and push to your fork:
  ```bash
  # from the cohort repo root:
  gh auth login        # one-time per machine; HTTPS + browser login is fine
  gh repo fork --remote-name=origin --clone=false
  git push -u origin main
  ```
  *WSL2 students:* `gh auth login`'s browser-open sometimes doesn't bridge from WSL — if it doesn't, paste the device-flow URL the terminal prints into your Windows browser manually.

- **Path B (clean history)** — fresh `git init` + new repo:
  ```bash
  rm -rf .git
  git init && git branch -M main
  git add . && git commit -m "Initial deploy of my bedtime story app"
  gh auth login
  gh repo create <your-repo-name> --public --source=. --remote=origin --push
  ```

**Verify before Phase 1:** `gh repo view --web` opens your repo in the browser. The page must show your code under *your* GitHub username — Render and Vercel will only see repos *you* own when they ask you to pick from a list.

### 1. Render backend + managed Postgres

- Sign in to <https://render.com>. *New → Blueprint*. Connect your GitHub repo.
- Render reads `render.yaml` and provisions both the web service (`bedtime-story-api`) and the managed Postgres database (`bedtime-story-db`). `DATABASE_URL` is auto-wired.
- After the first deploy completes, go to the service's *Environment* tab and set `GEMINI_API_KEY` to your Google AI Studio key. (Marked `sync: false` in `render.yaml` so it's not committed.)
- Apply the schema migration once. In the Render dashboard, click your `bedtime-story-db` card → **Connect** → copy the **External Database URL** (reachable from your laptop; the password is embedded — treat it like an API key). Then from your local terminal:
  ```bash
  psql "<paste-the-External-Database-URL-here>" -f sql/002_create_stories.sql
  ```
  Expected output: `DROP TABLE`, `CREATE TABLE`, `CREATE INDEX`. (If the dashboard shows an in-browser SQL shell instead, that works too — copy the contents of `sql/002_create_stories.sql` into it.)
- Note your service's URL — looks like `https://bedtime-story-api.onrender.com`.

### 2. Vercel frontend

- Sign in to <https://vercel.com>. *Add New → Project*. Import your GitHub repo.
- Vercel reads `vercel.json` and deploys `frontend/` as static files (no build step).
- Note your production URL — looks like `https://bedtime-story.vercel.app`.

### 3. Wire frontend → backend

Open `frontend/script.js`. Replace:
```javascript
const BACKEND_URL = "http://localhost:8000";
```
with:
```javascript
const BACKEND_URL = "https://bedtime-story-api.onrender.com";  // your Render URL
```
Commit and push. Vercel auto-redeploys in ~30 seconds, baking the new URL into the static JS that hits the browser.

### 4. Verify

Open the Vercel URL in a browser. Generate a story. Confirm it persists (`SELECT id, plot FROM stories ORDER BY id DESC LIMIT 1` from the Render shell). Click a saved story in the panel — confirm zero `/story` requests in DevTools (it serves from the database).

> **Free-tier reality check.** Render's free web service spins down after ~15 minutes of inactivity. The first request after a spin-down takes 30+ seconds (cold start). Render's free Postgres **expires 30 days after creation** (then a 14-day grace period before deletion — verified against Render docs, 2026). Free web services across your workspace are capped at **750 instance hours per calendar month**. For a 4-week cohort the database expiry needs explicit attention; for long-running classroom use, upgrade or migrate.

## Verify (locally, before deploy)

```bash
# All-in-one (server up + GEMINI_API_KEY exported):
./scripts/verify_module_7.sh
```

The script checks: `frontend/` exists with three files; `app/templates/` and `app/static/` deleted; CORS middleware wired in `app/main.py`; Jinja2/HTMLResponse/StaticFiles imports gone; `Procfile`, `render.yaml`, `vercel.json` present; `BACKEND_URL` constant in `script.js`; backend `/healthz` returns OK; CORS preflight to `/story` returns the expected headers; `/` and `/static` are 404; `/story` and `/stories` and `/healthz` work.

## Try asking Gemini

**Late tier — final module.** Two prompts, both reflective. By now you've shaped your own way of asking.

**Articulate the gain — why split, not serverless:**
> The PRD locked this architecture in §3: Vercel frontend (static), Render backend (long-running uvicorn) + managed Postgres. Not Vercel serverless. Make the strongest case you can for the *opposite* choice — full Vercel serverless. Then defend the split-stack version with reference to V1's "uvicorn long-running" mental model and the cost (in cohort time) of re-learning what a server is.

**Pick something that surprised you and explore it.**
> Open `app/main.py`, `frontend/script.js`, `Procfile`, `render.yaml`, and `vercel.json`. Pick one design choice that surprised you (the deletion of the `/` HTML route? CORS `allow_origins=["*"]` for V1? `BACKEND_URL` as a hardcoded JS constant instead of a build-step env var? `sync: false` on `GEMINI_API_KEY` in `render.yaml`? the two-terminal local-dev workflow?). Write a prompt to ask Gemini about it. Share what you learn with your peer or your instructor.

---

**Defend It (do not paste this into Gemini — answer it yourself):**
> *Why do we deploy the frontend as static files on Vercel and the backend as a long-running uvicorn process on Render — instead of running both on Vercel as serverless functions?*

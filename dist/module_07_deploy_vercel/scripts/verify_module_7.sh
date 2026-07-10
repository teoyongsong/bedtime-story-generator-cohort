#!/usr/bin/env bash
# verify_module_7.sh — Module 7: deploy split (Vercel frontend, Render backend + Postgres).
# Hard checks against the local repo + a running uvicorn at localhost:8000.

set -u
ok()   { echo "✓ $1"; }
fail() { echo "✗ $1"; exit 1; }

# Check 1: frontend/ exists with three files.
[ -d frontend ] || fail "frontend/ directory missing — Module 7 splits the frontend out."
for f in index.html style.css script.js; do
    [ -f "frontend/$f" ] || fail "frontend/$f missing."
done
ok "frontend/ exists with index.html, style.css, script.js"

# Check 2: BACKEND_URL constant + cross-origin fetch shape in script.js.
grep -q "const BACKEND_URL" frontend/script.js \
    || fail "frontend/script.js missing 'const BACKEND_URL' — students replace this per-deploy."
grep -q '\${BACKEND_URL}/story' frontend/script.js \
    || fail "frontend/script.js does not use \${BACKEND_URL}/story — fetches must be cross-origin-shaped."
grep -q '\${BACKEND_URL}/stories' frontend/script.js \
    || fail "frontend/script.js does not use \${BACKEND_URL}/stories — Module 6's retrieval must be wired."
ok "BACKEND_URL constant + cross-origin fetches present"

# Check 3: V1 backend HTML serving deleted.
[ ! -d app/templates ] || fail "app/templates/ still exists — Module 7 deletes it (Vercel serves the HTML)."
[ ! -d app/static ]    || fail "app/static/ still exists — Module 7 deletes it (Vercel serves the static files)."
ok "app/templates/ and app/static/ deleted"

# Check 4: Backend imports cleaned.
if grep -qE "Jinja2Templates|HTMLResponse|StaticFiles" app/main.py; then
    fail "app/main.py still imports Jinja2Templates / HTMLResponse / StaticFiles — should be removed (no HTML serving in Module 7's backend)."
fi
ok "Jinja2/HTMLResponse/StaticFiles imports removed from main.py"

# Check 5: index handler removed.
if grep -qE '@app\.get\("/"' app/main.py; then
    fail '/ route still defined in app/main.py — Vercel serves the frontend, FastAPI serves only JSON.'
fi
ok "/ index route removed from main.py"

# Check 6: CORS middleware in.
grep -q "from fastapi.middleware.cors import CORSMiddleware" app/main.py \
    || fail "app/main.py missing CORSMiddleware import."
grep -q "app.add_middleware(CORSMiddleware" app/main.py \
    || fail "app/main.py does not register CORSMiddleware — cross-origin requests from Vercel will fail."
ok "CORS middleware imported and registered"

# Check 7: requirements.txt — jinja2 dropped.
if grep -q "^jinja2" requirements.txt; then
    fail "jinja2 still pinned in requirements.txt — drop it; the backend no longer renders HTML."
fi
ok "jinja2 removed from requirements.txt"

# Check 8: deploy configs at repo root.
[ -f Procfile ]    || fail "Procfile missing — Render reads this to start the web service."
grep -q "uvicorn app.main:app" Procfile \
    || fail "Procfile does not invoke 'uvicorn app.main:app'."
ok "Procfile present (Render web start command)"

[ -f render.yaml ] || fail "render.yaml missing — declarative Render config (web service + managed Postgres)."
grep -q "bedtime-story-api" render.yaml \
    || fail "render.yaml missing 'bedtime-story-api' service name."
grep -q "fromDatabase:" render.yaml \
    || fail "render.yaml does not wire DATABASE_URL fromDatabase — managed Postgres connection must be auto-injected."
ok "render.yaml present (web service + managed Postgres + DATABASE_URL wiring)"

[ -f vercel.json ] || fail "vercel.json missing — Vercel deploy config."
grep -q '"outputDirectory":\s*"frontend"' vercel.json \
    || fail "vercel.json must point outputDirectory at the frontend/ folder."
ok "vercel.json present (frontend/ as outputDirectory)"

# Check 9: Backend boots and is JSON-only.
healthz=$(curl -s http://localhost:8000/healthz)
echo "$healthz" | grep -q '"postgres":' || fail "/healthz response missing postgres field."
ok "/healthz works (backend up)"

status_root=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/)
[ "$status_root" = "404" ] \
    || fail "GET / returned $status_root — expected 404 (Module 7 deletes the index route)."
ok "GET / → 404 (index route deleted)"

status_static=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/static/style.css)
[ "$status_static" = "404" ] \
    || fail "GET /static/style.css returned $status_static — expected 404 (StaticFiles mount removed)."
ok "GET /static/* → 404 (static mount removed)"

# Check 10: CORS preflight returns the expected headers.
cors_headers=$(curl -s -I -X OPTIONS http://localhost:8000/story \
    -H "Origin: https://bedtime-story.vercel.app" \
    -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: Content-Type")
echo "$cors_headers" | grep -qi "access-control-allow-origin" \
    || fail "CORS preflight to /story did not include access-control-allow-origin header. Browser would block the request from Vercel. Got headers: $cors_headers"
ok "CORS preflight to /story returns access-control-allow-origin"

# Check 11: /story and /stories still work (regression).
status_story_400=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/story \
    -H "Content-Type: application/json" \
    -d '{"child_name":" ","characters":"x","setting":"y","plot":"z"}')
[ "$status_story_400" = "400" ] \
    || fail "POST /story validation regressed: returned $status_story_400 (expected 400)."

status_stories_422=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8000/stories")
[ "$status_stories_422" = "422" ] \
    || fail "GET /stories without child_name regressed: returned $status_stories_422 (expected 422)."
ok "/story and /stories validation paths preserved"

echo
echo "Module 7 verification passed."
echo "Note: this verifies the LOCAL state of the deploy split. The actual deploy to"
echo "Vercel + Render is a manual procedure — see this folder's README.md for the"
echo "step-by-step. Confirm in production:"
echo "  1. Frontend at https://<your>.vercel.app loads, generates stories."
echo "  2. Backend at https://<your>.onrender.com/healthz returns {\"postgres\": true}."
echo "  3. After applying sql/002_create_stories.sql on Render's Postgres, /story"
echo "     persists rows; /stories?child_name=... returns them; click-to-rehear works."
echo "  4. (Optional) Tighten CORS allow_origins from [\"*\"] to your specific Vercel"
echo "     domain — production-hardening, named explicitly in the slide as a follow-up."

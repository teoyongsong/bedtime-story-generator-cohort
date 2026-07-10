#!/usr/bin/env bash
# verify_module_2.sh — Module 2: replace textarea with a structured form (StoryRequest).
#
# Soft check: the *content* of the generated story is non-deterministic. We hard-check
# the plumbing (file deletions, schema rewrite, endpoint shape, Pydantic validation,
# old endpoints removed) and emit a manual-inspection note for the story's quality.
#
# Assumes uvicorn is running on http://localhost:8000 with .env loaded
# (DATABASE_URL set, GEMINI_API_KEY set to a real key from
#  https://aistudio.google.com/apikey).

set -u
ok()   { echo "✓ $1"; }
fail() { echo "✗ $1"; exit 1; }

# Check 1: V1 persistence layer is deleted entirely.
[ ! -f app/services/interaction_service.py ] \
    || fail "app/services/interaction_service.py still exists — Module 2 deletes it. Module 6 will recreate as story_service.py."
ok "app/services/interaction_service.py deleted"

# Check 2: V1 Q&A schemas are gone, story schemas are present.
if grep -qE "class (AskRequest|AskResponse|Interaction)" app/schemas.py; then
    fail "Old Q&A schemas still present in app/schemas.py — should be replaced by StoryRequest/StoryResponse."
fi
ok "AskRequest/AskResponse/Interaction removed from app/schemas.py"

grep -q "class StoryRequest" app/schemas.py \
    || fail "StoryRequest class missing from app/schemas.py."
grep -q "class StoryResponse" app/schemas.py \
    || fail "StoryResponse class missing from app/schemas.py."
ok "StoryRequest + StoryResponse present in app/schemas.py"

# Check 3: All four typed fields on StoryRequest.
for field in child_name characters setting plot; do
    grep -qE "^\\s+${field}: str" app/schemas.py \
        || fail "StoryRequest missing field: ${field}: str"
done
ok "StoryRequest has child_name, characters, setting, plot (all str)"

# Check 4: /ask and /history handlers are removed from main.py.
if grep -qE '@app\.(post|get)\("/ask"' app/main.py; then
    fail "/ask handler still defined in app/main.py — should be removed (renamed to /story)."
fi
if grep -qE '@app\.get\("/history"' app/main.py; then
    fail "/history handler still defined in app/main.py — should be removed (Module 6 will introduce /stories)."
fi
ok "/ask and /history handlers removed from app/main.py"

# Check 5: /story handler is defined.
grep -qE '@app\.post\("/story"' app/main.py \
    || fail "/story handler not defined in app/main.py."
ok "/story handler defined in app/main.py"

# Check 6: interaction_service is no longer imported anywhere.
if grep -r "interaction_service" app/; then
    fail "Found reference to interaction_service in app/ — should be deleted entirely."
fi
ok "No references to interaction_service in app/"

# Check 7: index.html has the new form, not the old textarea.
grep -q 'id="story-form"' app/templates/index.html \
    || fail 'app/templates/index.html missing the new <form id="story-form"> element.'
if grep -q 'id="question"' app/templates/index.html; then
    fail 'app/templates/index.html still has the old <textarea id="question"> — should be replaced by the form.'
fi
ok "index.html uses the structured form (story-form), no old textarea"

# Check 8: /healthz still works (regression check).
healthz=$(curl -s http://localhost:8000/healthz)
echo "$healthz" | grep -q '"postgres":' \
    || fail "/healthz response missing postgres field. Got: $healthz"
ok "/healthz still reports postgres (no regression from Module 1)"

# Check 9: /story returns 200 + story field for a valid payload.
resp=$(curl -s -X POST http://localhost:8000/story \
    -H "Content-Type: application/json" \
    -d '{"child_name":"verify-module-2","characters":"a brave rabbit and a wise turtle","setting":"a moonlit meadow","plot":"finding the way home before the stars come out"}')
echo "$resp" | grep -q '"story":"' \
    || fail "/story response missing story field. Got: $resp"
ok "POST /story returns a story (Gemini reachable, prompt composed)"

# Check 10: Pydantic 422 on missing required fields.
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/story \
    -H "Content-Type: application/json" -d '{"child_name":"only-this"}')
[ "$status" = "422" ] \
    || fail "POST /story with missing fields returned $status — expected 422 (Pydantic validation)."
ok "POST /story with missing required fields → 422 (Pydantic validation)"

# Check 11: Handler 400 on blank child_name.
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/story \
    -H "Content-Type: application/json" \
    -d '{"child_name":"   ","characters":"x","setting":"y","plot":"z"}')
[ "$status" = "400" ] \
    || fail "POST /story with blank child_name returned $status — expected 400 (handler validation)."
ok "POST /story with blank child_name → 400 (handler validation)"

# Check 12: Old endpoints are 404.
ask_status=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/ask \
    -H "Content-Type: application/json" -d '{"question":"hi"}')
[ "$ask_status" = "404" ] \
    || fail "POST /ask returned $ask_status — expected 404 (endpoint removed)."
hist_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/history)
[ "$hist_status" = "404" ] \
    || fail "GET /history returned $hist_status — expected 404 (endpoint removed)."
ok "POST /ask → 404 and GET /history → 404 (V1 endpoints removed)"

echo
echo "Module 2 verification passed."
echo "Note: the *content* of the generated story is non-deterministic. Manually inspect"
echo "that the most recent /story response (visible in the browser) reads as a coherent"
echo "short bedtime story that mentions the child's name, the characters, the setting,"
echo "and the plot. If the story ignores one of the form fields, the inline f-string in"
echo "the /story handler is misformatted — re-read the prompt construction in main.py."
echo "If the story is too long, too violent, or wrong-tone, that's Module 4's lesson"
echo "(strengthening the system prompt with safety constraints) — do not fix it here."

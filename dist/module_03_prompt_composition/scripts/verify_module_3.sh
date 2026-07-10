#!/usr/bin/env bash
# verify_module_3.sh — Module 3: lift inline prompt into compose_story_prompt(req).
#
# Soft check: the *content* of the generated story is non-deterministic. We hard-check
# the plumbing (new file present, function imports cleanly, handler uses it, validation
# paths preserved, behaviour-equivalence holds) and emit a manual-inspection note.
#
# This module is a pure refactor — same /story shape, same validation, same response
# structure. Anything that broke would be a regression, not a Module-3 feature.
#
# Assumes uvicorn is running on http://localhost:8000 with .env loaded
# (DATABASE_URL set, GEMINI_API_KEY set to a real key from
#  https://aistudio.google.com/apikey).

set -u
ok()   { echo "✓ $1"; }
fail() { echo "✗ $1"; exit 1; }

# Check 1: app/prompt.py exists.
[ -f app/prompt.py ] \
    || fail "app/prompt.py missing — Module 3 creates this file (peer to app/schemas.py)."
ok "app/prompt.py present"

# Check 2: It's a peer to schemas.py, NOT under app/services/.
if [ -f app/services/prompt.py ]; then
    fail "Found app/services/prompt.py — should be app/prompt.py (peer to schemas.py). The services/ folder is for code that talks to external concerns; prompt composition is pure logic."
fi
ok "app/prompt.py is correctly placed (peer to schemas.py, not under services/)"

# Check 3: compose_story_prompt is defined and signed correctly.
grep -qE "def compose_story_prompt\(req: StoryRequest\) -> str" app/prompt.py \
    || fail "compose_story_prompt(req: StoryRequest) -> str not defined in app/prompt.py."
ok "compose_story_prompt(req: StoryRequest) -> str defined"

# Check 4: main.py imports and calls it.
grep -q "from app.prompt import compose_story_prompt" app/main.py \
    || fail "app/main.py does not import compose_story_prompt from app.prompt."
grep -q "compose_story_prompt(payload)" app/main.py \
    || fail "app/main.py does not call compose_story_prompt(payload) in the /story handler."
ok "main.py imports and calls compose_story_prompt"

# Check 5: The Module 2 inline f-string is gone from main.py.
if grep -qE 'f"Write a short bedtime story for a child named \{payload\.' app/main.py; then
    fail "Module 2's inline f-string still in app/main.py — should be removed (the handler should call compose_story_prompt(payload) instead)."
fi
ok "Module 2's inline f-string removed from app/main.py"

# Check 6: The Module 2 'lift this' comment is gone from main.py.
if grep -q "Module 3 lifts this" app/main.py; then
    fail "The Module 2 comment '# Module 3 lifts this inline f-string...' is still in app/main.py — Module 3 IS the lift; the comment should be deleted."
fi
ok "Module 2's promissory comment removed (the lift is done)"

# Check 7: compose_story_prompt is unit-callable and applies .strip() + multi-line structure.
out=$(python -c "
from app.schemas import StoryRequest
from app.prompt import compose_story_prompt
req = StoryRequest(child_name='  Aisha  ', characters='owl  ', setting='\nforest', plot='moon\n')
print(compose_story_prompt(req))
")
echo "$out" | grep -qE "^Write a short bedtime story for a child named Aisha\." \
    || fail "compose_story_prompt did not produce expected intro line with stripped child_name. Got: $out"
echo "$out" | grep -qE "^Characters: owl$" \
    || fail "compose_story_prompt did not strip 'characters' or did not put it on its own line. Got: $out"
echo "$out" | grep -qE "^Setting: forest$" \
    || fail "compose_story_prompt did not strip 'setting' or did not put it on its own line. Got: $out"
echo "$out" | grep -qE "^Plot: moon$" \
    || fail "compose_story_prompt did not strip 'plot' or did not put it on its own line. Got: $out"
ok "compose_story_prompt strips whitespace + emits multi-line labelled prompt"

# Check 8: /healthz still works (regression check).
healthz=$(curl -s http://localhost:8000/healthz)
echo "$healthz" | grep -q '"postgres":' \
    || fail "/healthz response missing postgres field. Got: $healthz"
ok "/healthz still reports postgres (no regression from Module 2)"

# Check 9: /story returns 200 + story field for a valid payload.
resp=$(curl -s -X POST http://localhost:8000/story \
    -H "Content-Type: application/json" \
    -d '{"child_name":"verify-module-3","characters":"a brave rabbit and a wise turtle","setting":"a moonlit meadow","plot":"finding the way home before the stars come out"}')
echo "$resp" | grep -q '"story":"' \
    || fail "/story response missing story field. Got: $resp"
ok "POST /story returns a story (Gemini reachable, refactor preserves behaviour)"

# Check 10: Pydantic 422 on missing fields (regression check).
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/story \
    -H "Content-Type: application/json" -d '{"child_name":"only-this"}')
[ "$status" = "422" ] \
    || fail "POST /story with missing fields returned $status — expected 422. Module 3 should not change validation behaviour."
ok "POST /story with missing fields → 422 (regression check passed)"

# Check 11: Handler 400 on blank required (regression check).
status=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/story \
    -H "Content-Type: application/json" \
    -d '{"child_name":"   ","characters":"x","setting":"y","plot":"z"}')
[ "$status" = "400" ] \
    || fail "POST /story with blank child_name returned $status — expected 400. Module 3 should not change validation behaviour."
ok "POST /story with blank child_name → 400 (regression check passed)"

# Check 12: /ask and /history still 404 (regression check from Module 2).
ask_status=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/ask -d '{}')
hist_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/history)
[ "$ask_status" = "404" ] && [ "$hist_status" = "404" ] \
    || fail "Old endpoints regressed: /ask=$ask_status, /history=$hist_status (both should be 404)."
ok "POST /ask → 404 and GET /history → 404 (regression check passed)"

echo
echo "Module 3 verification passed."
echo "Note: this is a pure refactor — the *content* of the generated story is still"
echo "non-deterministic. Manually inspect that the most recent /story response (visible"
echo "in the browser) reads as a coherent short bedtime story that mentions the child's"
echo "name, the characters, the setting, and the plot — same property as Module 2."
echo "If the multi-line + .strip() prompt structure causes Gemini to produce visibly"
echo "MORE-paragraphed stories than Module 2 did, that's expected — the prompt's"
echo "structure influences the model's output structure. That IS the lesson of"
echo "'prompt composition with rules and care.'"

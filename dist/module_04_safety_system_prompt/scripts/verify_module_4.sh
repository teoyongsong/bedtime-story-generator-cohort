#!/usr/bin/env bash
# verify_module_4.sh — Module 4: SYSTEM_PROMPT moves to app/system_prompt.py
# and gains bedtime-story safety constraints.
#
# Soft check: the *behaviour* of the model under safety constraints is
# non-deterministic. We hard-check the plumbing (file present, gemini_service
# imports the new constant, content markers in the prompt, regression checks
# for /story shape and validation) and emit a manual-inspection rubric for
# the "scary plot" experiment.
#
# Assumes uvicorn is running on http://localhost:8000 with .env loaded
# (DATABASE_URL set, GEMINI_API_KEY set to a real key from
#  https://aistudio.google.com/apikey).

set -u
ok()   { echo "✓ $1"; }
fail() { echo "✗ $1"; exit 1; }

# Check 1: app/system_prompt.py exists.
[ -f app/system_prompt.py ] \
    || fail "app/system_prompt.py missing — Module 4 creates this file (sibling to app/prompt.py)."
ok "app/system_prompt.py present"

# Check 2: It's a sibling of prompt.py, NOT under app/services/.
if [ -f app/services/system_prompt.py ]; then
    fail "Found app/services/system_prompt.py — should be app/system_prompt.py (sibling to app/prompt.py). The services/ folder is for code that talks to external concerns; the system prompt is a behavioural design surface."
fi
ok "app/system_prompt.py is correctly placed (sibling to prompt.py, not under services/)"

# Check 3: SYSTEM_PROMPT no longer defined in gemini_service.py.
if grep -qE '^SYSTEM_PROMPT = \(' app/services/gemini_service.py; then
    fail "SYSTEM_PROMPT is still defined in app/services/gemini_service.py — should be moved to app/system_prompt.py and imported."
fi
ok "SYSTEM_PROMPT no longer defined in gemini_service.py (moved out)"

# Check 4: gemini_service.py imports it from the new home.
grep -q "from app.system_prompt import SYSTEM_PROMPT" app/services/gemini_service.py \
    || fail "app/services/gemini_service.py does not import SYSTEM_PROMPT from app.system_prompt."
ok "gemini_service.py imports SYSTEM_PROMPT from app.system_prompt"

# Check 5: The leftover Q&A framing is gone.
if grep -q "concise, helpful assistant" app/system_prompt.py; then
    fail "The Q&A-shaped 'concise, helpful assistant' framing is still in app/system_prompt.py — should be replaced with bedtime-story-shaped constraints."
fi
ok "Old Q&A framing removed from system prompt"

# Check 6: New bedtime-story framing is present.
grep -q "bedtime stories" app/system_prompt.py \
    || fail "New SYSTEM_PROMPT does not mention 'bedtime stories' — the domain framing is missing."
ok "New SYSTEM_PROMPT names the bedtime-story domain"

# Check 7: Each safety / tone constraint is present (proxy by keyword).
# Python adjacent-string concatenation joins `"abc "` and `"def"` into `"abc def"`
# at compile time. We simulate that here so that constraints which wrap across
# adjacent string literals (like "do not address the reader as 'you'") still
# match: drop newlines, then strip the `"<spaces>"` inter-literal boundary.
prompt_text=$(tr -d '\n' < app/system_prompt.py | sed 's/" *"//g')
echo "$prompt_text" | grep -q "five paragraphs at most" \
    || fail "Length-cap constraint missing — expected 'five paragraphs at most'."
echo "$prompt_text" | grep -q "No violence" \
    || fail "No-violence constraint missing — expected explicit 'No violence' wording."
echo "$prompt_text" | grep -q "safe, comforted" \
    || fail "Gentle-resolution constraint missing — expected 'safe, comforted' wording."
echo "$prompt_text" | grep -q "sensory details" \
    || fail "Sensory-detail constraint missing — expected 'sensory details' wording."
echo "$prompt_text" | grep -q "do not address the reader as 'you'" \
    || fail "No-second-person constraint missing — expected \"do not address the reader as 'you'\" wording."
ok "All five safety/tone constraints present in SYSTEM_PROMPT"

# Check 8: Refuse-with-grace clause present.
echo "$prompt_text" | grep -q "gently steer" \
    || fail "Refuse-with-grace clause missing — expected 'gently steer' wording. Production prompts steer, they don't lecture."
ok "Refuse-with-grace clause present (gently steer, do not lecture)"

# Check 9: /healthz still works (regression).
healthz=$(curl -s http://localhost:8000/healthz)
echo "$healthz" | grep -q '"postgres":' \
    || fail "/healthz response missing postgres field. Got: $healthz"
ok "/healthz still reports postgres (no regression from Module 3)"

# Check 10: /story still returns 200 + story for a benign payload (regression).
resp=$(curl -s -X POST http://localhost:8000/story \
    -H "Content-Type: application/json" \
    -d '{"child_name":"verify-module-4","characters":"a kind dragon and a clever mouse","setting":"a starlit pond","plot":"learning to share the last lily pad"}')
echo "$resp" | grep -q '"story":"' \
    || fail "/story response missing story field. Got: $resp"
ok "POST /story still returns a story (Gemini reachable, system prompt wired through)"

# Check 11: Validation paths preserved (regression).
status_422=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/story \
    -H "Content-Type: application/json" -d '{"child_name":"x"}')
status_400=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/story \
    -H "Content-Type: application/json" \
    -d '{"child_name":" ","characters":"x","setting":"y","plot":"z"}')
[ "$status_422" = "422" ] && [ "$status_400" = "400" ] \
    || fail "Validation regressed: missing-field=$status_422 (want 422), blank-required=$status_400 (want 400)."
ok "Pydantic 422 + handler 400 validation paths preserved"

echo
echo "Module 4 verification passed."
echo "Note: the *behaviour* of the model under safety constraints is non-deterministic."
echo "Manually inspect the demo:"
echo "  1. Send a benign plot (e.g. 'looking for the moon') — the story should be"
echo "     SHORTER and MORE PARAGRAPHED than Module 3's stories were, and should"
echo "     refer to the child by NAME (never as 'you')."
echo "  2. Send a deliberately scary plot (e.g. 'a monster chases them at night')"
echo "     — the story should INCLUDE the monster and the chase (the model is not"
echo "     censoring) BUT end with all named characters safe and at rest. The model"
echo "     should NOT refuse with 'I cannot write that' — that would mean the"
echo "     'gently steer' clause is being ignored."
echo "If the model refuses outright, the SYSTEM_PROMPT's refuse-with-grace wording"
echo "needs to be more explicit (production-prompt iteration is part of the lesson)."
echo "If the model produces graphic violence or a sad ending, the safety constraints"
echo "need to be re-emphasised (try moving them earlier in the prompt, or repeating"
echo "them at the end)."

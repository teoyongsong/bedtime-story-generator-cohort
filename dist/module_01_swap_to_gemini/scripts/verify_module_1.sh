#!/usr/bin/env bash
# verify_module_1.sh — Module 1: swap Ollama for the Gemini API (google-genai SDK).
#
# Soft check: the *content* of the LLM's answer is non-deterministic — different
# strings on every call. We hard-check the plumbing (file deletions, file additions,
# constants present, response shape, postgres model_name string) and emit a
# manual-inspection note for the answer's quality at the end.
#
# Assumes uvicorn is running on http://localhost:8000 with .env loaded
# (DATABASE_URL set, GEMINI_API_KEY set to a real key from
#  https://aistudio.google.com/apikey).

set -u
ok()   { echo "✓ $1"; }
fail() { echo "✗ $1"; exit 1; }

: "${DATABASE_URL:?DATABASE_URL must be exported (set in .env, or export it before running)}"

# Check 1: The V1 Ollama service file is gone.
[ ! -f app/services/ollama_service.py ] \
    || fail "app/services/ollama_service.py still exists — Module 1 deletes it entirely."
ok "app/services/ollama_service.py deleted"

# Check 2: The new Gemini service file exists.
[ -f app/services/gemini_service.py ] \
    || fail "app/services/gemini_service.py missing — Module 1 creates this file."
ok "app/services/gemini_service.py present"

# Check 3: The new SDK is imported (not the deprecated package).
grep -q "from google import genai" app/services/gemini_service.py \
    || fail "app/services/gemini_service.py must import 'from google import genai' (the actively-maintained SDK)."
ok "google-genai SDK imported (not the deprecated google-generativeai)"

if grep -rq "import google.generativeai" app/; then
    fail "Found 'import google.generativeai' somewhere in app/. That package is deprecated; use 'from google import genai'."
fi
ok "No references to the deprecated google.generativeai package"

# Check 4: GEMINI_MODEL constant present and consumed by interaction_service.
grep -q 'GEMINI_MODEL = "gemini-' app/services/gemini_service.py \
    || fail "GEMINI_MODEL constant not set in app/services/gemini_service.py."
ok "GEMINI_MODEL constant defined in gemini_service.py"

grep -q "from app.services.gemini_service import GEMINI_MODEL" app/services/interaction_service.py \
    || fail "interaction_service.py must import GEMINI_MODEL from gemini_service (was OLLAMA_MODEL in V1)."
ok "interaction_service.py imports GEMINI_MODEL"

# Check 5: GEMINI_API_KEY read from os.environ (loud-fail discipline preserved).
grep -q 'os.environ\["GEMINI_API_KEY"\]' app/services/gemini_service.py \
    || fail 'GEMINI_API_KEY not read from os.environ in app/services/gemini_service.py — the loud-fail-on-missing rule must hold.'
ok "GEMINI_API_KEY read from os.environ (loud-fail on missing)"

# Check 6: httpx is gone from requirements (the only V1 callers — Ollama + healthz — are deleted).
if grep -q "^httpx" requirements.txt; then
    fail "httpx still pinned in requirements.txt — its only callers (Ollama + healthz Ollama probe) are deleted; drop the line."
fi
ok "httpx removed from requirements.txt"

grep -q "^google-genai" requirements.txt \
    || fail "google-genai not pinned in requirements.txt."
ok "google-genai pinned in requirements.txt"

# Check 7: /healthz no longer reports Ollama.
healthz=$(curl -s http://localhost:8000/healthz)
echo "$healthz" | grep -q '"postgres":' \
    || fail "/healthz response missing postgres field. Got: $healthz"
if echo "$healthz" | grep -q '"ollama":'; then
    fail "/healthz still reports an ollama field. The Ollama branch should be deleted entirely. Got: $healthz"
fi
ok "/healthz reports postgres only (Ollama branch removed)"

# Check 8: /ask returns a non-empty answer + history.
resp=$(curl -s -X POST http://localhost:8000/ask \
    -H "Content-Type: application/json" \
    -d '{"question":"verify module 1: name one Python web framework"}')
echo "$resp" | grep -q '"answer":"' \
    || fail "/ask response missing answer field. Got: $resp"
echo "$resp" | grep -q '"history":' \
    || fail "/ask response missing history field. Got: $resp"
ok "POST /ask returns answer + history (Gemini reachable)"

# Check 9: Postgres recorded the new model name.
last_model=$(psql "$DATABASE_URL" -tAc \
    "SELECT model_name FROM interactions ORDER BY id DESC LIMIT 1")
[ "$last_model" = "gemini-2.5-flash-lite" ] \
    || fail "Latest interactions.model_name is '$last_model' — expected 'gemini-2.5-flash-lite'."
ok "Postgres recorded model_name = gemini-2.5-flash-lite"

echo
echo "Module 1 verification passed."
echo "Note: the *content* of the Gemini answer is non-deterministic. Manually inspect"
echo "that the most recent /ask answer (visible in the browser or in psql) is a coherent"
echo "English sentence on the asked topic, ≤ ~80 words, and admits unknowns when asked"
echo "something it can't know. If answers are gibberish, empty, or wildly off-topic,"
echo "the system_instruction wiring in gemini_service.py is broken — re-check that"
echo "GenerateContentConfig(system_instruction=SYSTEM_PROMPT) is being passed to"
echo "client.models.generate_content(...)."

#!/usr/bin/env bash
# verify_module_6.sh — Module 6: stories table + story_service + /stories endpoint + UI panel.
# Assumes the migration sql/002_create_stories.sql has been applied.
# Assumes uvicorn is running on http://localhost:8000.

set -u
ok()   { echo "✓ $1"; }
fail() { echo "✗ $1"; exit 1; }

: "${DATABASE_URL:?DATABASE_URL must be exported}"

# Check 1: Migration file exists and contains the expected DDL.
[ -f sql/002_create_stories.sql ] || fail "sql/002_create_stories.sql missing."
grep -q "DROP TABLE IF EXISTS interactions" sql/002_create_stories.sql \
    || fail "Migration must DROP the V1 interactions table."
grep -q "CREATE TABLE stories" sql/002_create_stories.sql \
    || fail "Migration must CREATE the stories table."
grep -q "idx_stories_child_name_created_at" sql/002_create_stories.sql \
    || fail "Migration must create the composite index idx_stories_child_name_created_at."
ok "sql/002_create_stories.sql present (DROP interactions + CREATE stories + composite index)"

# Check 2: Migration has been applied.
have_stories=$(psql "$DATABASE_URL" -tAc "SELECT 1 FROM information_schema.tables WHERE table_name='stories'")
[ "$have_stories" = "1" ] || fail "stories table not present in DB. Run: psql \"\$DATABASE_URL\" -f sql/002_create_stories.sql"
ok "stories table exists in DB"

have_interactions=$(psql "$DATABASE_URL" -tAc "SELECT 1 FROM information_schema.tables WHERE table_name='interactions'")
[ -z "$have_interactions" ] || fail "interactions table still in DB — migration should have DROPped it."
ok "V1 interactions table dropped"

have_index=$(psql "$DATABASE_URL" -tAc "SELECT 1 FROM pg_indexes WHERE indexname='idx_stories_child_name_created_at'")
[ "$have_index" = "1" ] || fail "Composite index idx_stories_child_name_created_at missing."
ok "Composite index (child_name, created_at DESC) present"

# Check 3: app/services/story_service.py exists with both functions.
[ -f app/services/story_service.py ] || fail "app/services/story_service.py missing."
grep -q "def save_story" app/services/story_service.py \
    || fail "save_story not defined in story_service.py."
grep -q "def fetch_recent_stories" app/services/story_service.py \
    || fail "fetch_recent_stories not defined in story_service.py."
ok "story_service.py present (save_story + fetch_recent_stories)"

# Check 4: StoredStory schema added.
grep -q "class StoredStory" app/schemas.py \
    || fail "StoredStory class missing from app/schemas.py."
ok "StoredStory schema present"

# Check 5: /story handler persists.
grep -q "save_story(payload, story_text)" app/main.py \
    || fail "/story handler does not call save_story(payload, story_text)."
ok "/story handler persists (save_story call wired)"

# Check 6: /stories endpoint defined.
grep -qE '@app\.get\("/stories"' app/main.py \
    || fail "/stories endpoint not defined in app/main.py."
ok "GET /stories endpoint defined"

# Check 7: UI panel + JS.
grep -q 'id="recent-stories"' app/templates/index.html \
    || fail "Past stories panel <aside id=\"recent-stories\"> missing from index.html."
grep -q "loadRecentStories" app/templates/index.html \
    || fail "loadRecentStories JS function missing from index.html."
grep -q "recent-item" app/templates/index.html \
    || fail "recent-item rendering missing — clicking a saved story should render it without re-calling Gemini."
ok "UI panel + click-to-rehear JS wired"

# Check 8: /healthz still works (regression).
healthz=$(curl -s http://localhost:8000/healthz)
echo "$healthz" | grep -q '"postgres":' || fail "/healthz response missing postgres field."
ok "/healthz still reports postgres (no regression)"

# Check 9: POST /story persists a row + returns story.
verify_name="verify-mod6-$$"
resp=$(curl -s -X POST http://localhost:8000/story -H "Content-Type: application/json" \
    -d "{\"child_name\":\"$verify_name\",\"characters\":\"a brave rabbit\",\"setting\":\"a meadow\",\"plot\":\"finding home\"}")
echo "$resp" | grep -q '"story":"' || fail "POST /story missing story field. Got: $resp"
row_count=$(psql "$DATABASE_URL" -tAc "SELECT COUNT(*) FROM stories WHERE child_name = '$verify_name'")
[ "$row_count" -ge 1 ] || fail "POST /story did not persist a row for child_name=$verify_name."
ok "POST /story persisted a row + returned a story"

# Check 10: GET /stories?child_name=... returns the row.
list=$(curl -s "http://localhost:8000/stories?child_name=$verify_name")
echo "$list" | grep -q "\"child_name\":\"$verify_name\"" \
    || fail "GET /stories did not return the row just persisted. Got: $list"
echo "$list" | grep -q '"body":"' \
    || fail "GET /stories response missing body field."
ok "GET /stories?child_name=... returns the persisted row(s)"

# Check 11: GET /stories with no query param → 422 (Pydantic).
status=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8000/stories")
[ "$status" = "422" ] || fail "GET /stories without child_name returned $status — expected 422."
ok "GET /stories without child_name → 422 (Pydantic validation)"

# Check 12: regression — /story validation paths.
status_422=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/story \
    -H "Content-Type: application/json" -d '{"child_name":"x"}')
status_400=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/story \
    -H "Content-Type: application/json" \
    -d '{"child_name":" ","characters":"x","setting":"y","plot":"z"}')
[ "$status_422" = "422" ] && [ "$status_400" = "400" ] \
    || fail "Validation regressed: 422=$status_422, 400=$status_400."
ok "/story validation paths preserved"

echo
echo "Module 6 verification passed."
echo "Note: the click-to-rehear behaviour (clicking a saved story renders the body"
echo "      WITHOUT calling Gemini) is best inspected manually in the browser."
echo "  1. Generate two stories for the same child_name."
echo "  2. Open DevTools Network tab. Click an older story in the panel."
echo "  3. Confirm: zero requests to /story; the story-pane fills with the saved body."
echo "If the click triggers a /story call, the click handler is regenerating instead"
echo "of serving from data-body — the lesson (and the cost-saving) is lost."

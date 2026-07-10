#!/usr/bin/env bash
# verify_module_5.sh — Module 5: two-column UI for parents reading aloud.
# Frontend-only module; backend regression checks ensure nothing slipped.
#
# Assumes uvicorn is running on http://localhost:8000.

set -u
ok()   { echo "✓ $1"; }
fail() { echo "✗ $1"; exit 1; }

# Check 1: HTML has the new semantic structure.
html=$(curl -s http://localhost:8000/)
echo "$html" | grep -q 'class="layout"' \
    || fail "index.html missing <main class=\"layout\"> — Module 5 introduces the two-column grid."
echo "$html" | grep -q 'class="form-pane"' \
    || fail "index.html missing <section class=\"form-pane\">."
echo "$html" | grep -q 'class="story-pane"' \
    || fail "index.html missing <section class=\"story-pane\">."
ok "index.html has layout, form-pane, story-pane sections"

# Check 2: aria-live on the story pane (accessibility detail).
echo "$html" | grep -q 'aria-live="polite"' \
    || fail 'index.html missing aria-live="polite" — story pane should announce updates politely.'
ok "story-pane is aria-live=polite"

# Check 3: Three explicit story states are wired up.
grep -q 'story-empty' app/templates/index.html \
    || fail "story-empty class not used in index.html."
grep -q 'story-loading' app/templates/index.html \
    || fail "story-loading class not used in index.html."
grep -q 'story-rendered' app/templates/index.html \
    || fail "story-rendered class not used in index.html."
ok "Three explicit story states (empty/loading/rendered) wired in JS"

# Check 4: V1 history panel is gone (regression check from Module 2).
if grep -q "renderHistory\|loadHistory\|/history" app/templates/index.html; then
    fail "V1 history panel JS or fetch crept back into index.html."
fi
ok "No V1 history panel in HTML/JS"

# Check 5: CSS uses Grid (not just flexbox stacking).
css=$(curl -s http://localhost:8000/static/style.css)
echo "$css" | grep -q 'grid-template-columns' \
    || fail "style.css does not use grid-template-columns — Module 5 uses CSS Grid for the two-column layout."
ok "style.css uses CSS Grid for layout"

# Check 6: Responsive breakpoint exists.
echo "$css" | grep -q '@media' \
    || fail "style.css has no @media query — Module 5 must collapse to single column on phones."
ok "style.css has a responsive @media breakpoint"

# Check 7: Serif story body.
echo "$css" | grep -q 'Georgia' \
    || fail "style.css does not declare Georgia (or another serif) for the story body — read-aloud typography lesson."
ok "style.css uses serif (Georgia) for story body"

# Check 8: Form-pane dim rule lives in CSS, not JS.
echo "$css" | grep -q 'body.story-active' \
    || fail "style.css missing body.story-active rule — the form-pane dim should be CSS-driven, not inline-style-driven."
ok "Form-pane dim driven by body.story-active CSS rule"

# Check 9: Backend regression — /story still works.
resp=$(curl -s -X POST http://localhost:8000/story \
    -H "Content-Type: application/json" \
    -d '{"child_name":"verify-module-5","characters":"a kind dragon","setting":"a quiet meadow","plot":"finding a place to nap"}')
echo "$resp" | grep -q '"story":"' \
    || fail "POST /story missing story field. Got: $resp"
ok "POST /story still returns a story (no backend regression)"

# Check 10: Validation paths preserved.
status_422=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/story \
    -H "Content-Type: application/json" -d '{"child_name":"x"}')
status_400=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/story \
    -H "Content-Type: application/json" \
    -d '{"child_name":" ","characters":"x","setting":"y","plot":"z"}')
[ "$status_422" = "422" ] && [ "$status_400" = "400" ] \
    || fail "Validation regressed: 422=$status_422, 400=$status_400."
ok "Pydantic 422 + handler 400 validation paths preserved"

echo
echo "Module 5 verification passed."
echo "Note: visual quality is a manual-inspection concern. Open the page in a browser:"
echo "  - Does the form sit on the left, the story area on the right (≥700px)?"
echo "  - After generating a story, does the form pane visibly dim (opacity 0.6)?"
echo "  - Is the story rendered in serif, generously spaced, on a cream-colored pane?"
echo "  - Resize narrower than 700px: does the layout collapse to a single stacked column?"
echo "If any of these fail, the corresponding CSS rule needs work — the *visible feel* is"
echo "the lesson, not just the structural presence of grid + media query."

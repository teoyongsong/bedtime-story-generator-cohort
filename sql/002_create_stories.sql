-- Module 6 — bury the V1 Q&A table; introduce the bedtime-story-shaped table.
-- Apply with:  psql "$DATABASE_URL" -f sql/002_create_stories.sql

DROP TABLE IF EXISTS interactions;

CREATE TABLE stories (
    id          SERIAL PRIMARY KEY,
    child_name  TEXT NOT NULL,
    characters  TEXT NOT NULL,
    setting     TEXT NOT NULL,
    plot        TEXT NOT NULL,
    body        TEXT NOT NULL,        -- the generated story body, stored verbatim
    model_name  TEXT NOT NULL,        -- e.g. 'gemini-2.5-flash-lite' — same column shape as V1's interactions
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_stories_child_name_created_at
    ON stories (child_name, created_at DESC);

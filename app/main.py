from dotenv import load_dotenv

load_dotenv()  # Must run BEFORE importing modules that read os.environ at load time.

import psycopg
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from app.database import get_conn
from app.prompt import compose_story_prompt
from app.schemas import StoredStory, StoryRequest, StoryResponse
from app.services.gemini_service import call_gemini
from app.services.story_service import fetch_recent_stories, save_story

app = FastAPI(title="Bedtime Story Generator")

# V1 simplicity: allow any origin so the Vercel-deployed frontend can call the
# Render-deployed backend without per-domain configuration. Tighten to your
# actual Vercel domain in production:
#     allow_origins=["https://bedtime-story.vercel.app"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.post("/story", response_model=StoryResponse)
def story(payload: StoryRequest):
    if not payload.child_name.strip() or not payload.plot.strip():
        raise HTTPException(
            status_code=400,
            detail="Please fill in at least the child's name and the plot.",
        )
    story_text = call_gemini(compose_story_prompt(payload))
    save_story(payload, story_text)
    return StoryResponse(story=story_text)


@app.get("/stories", response_model=list[StoredStory])
def stories(child_name: str):
    if not child_name.strip():
        raise HTTPException(status_code=400, detail="child_name query parameter is required.")
    return fetch_recent_stories(child_name)


@app.get("/healthz")
def healthz():
    status = {"postgres": False}
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
        status["postgres"] = True
    except psycopg.Error:
        pass
    return status

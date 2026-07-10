from dotenv import load_dotenv

load_dotenv()  # Must run BEFORE importing modules that read os.environ at load time.

import psycopg
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles

from app.database import get_conn
from app.schemas import StoryRequest, StoryResponse
from app.services.gemini_service import call_gemini

app = FastAPI(title="Bedtime Story Generator")

app.mount("/static", StaticFiles(directory="app/static"), name="static")
templates = Jinja2Templates(directory="app/templates")


@app.get("/", response_class=HTMLResponse)
def index(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})


@app.post("/story", response_model=StoryResponse)
def story(payload: StoryRequest):
    if not payload.child_name.strip() or not payload.plot.strip():
        raise HTTPException(
            status_code=400,
            detail="Please fill in at least the child's name and the plot.",
        )
    # Module 3 lifts this inline f-string into compose_story_prompt(payload).
    prompt = (
        f"Write a short bedtime story for a child named {payload.child_name}. "
        f"Characters: {payload.characters}. "
        f"Setting: {payload.setting}. "
        f"Plot: {payload.plot}."
    )
    return StoryResponse(story=call_gemini(prompt))


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

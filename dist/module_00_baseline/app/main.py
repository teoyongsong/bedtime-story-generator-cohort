from dotenv import load_dotenv

load_dotenv()  # Must run BEFORE importing modules that read os.environ at load time.

import httpx
import psycopg
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles

from app.database import get_conn
from app.schemas import AskRequest, AskResponse, Interaction
from app.services.ollama_service import OLLAMA_BASE_URL, call_ollama
from app.services.interaction_service import save_interaction, fetch_recent_history

app = FastAPI(title="Local LLM Question Log")

app.mount("/static", StaticFiles(directory="app/static"), name="static")
templates = Jinja2Templates(directory="app/templates")


@app.get("/", response_class=HTMLResponse)
def index(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})


@app.post("/ask", response_model=AskResponse)
def ask(payload: AskRequest):
    question = payload.question.strip()
    if not question:
        raise HTTPException(status_code=400, detail="Please enter a question.")
    answer = call_ollama(question)
    save_interaction(question, answer)
    return AskResponse(answer=answer, history=fetch_recent_history())


@app.get("/history", response_model=list[Interaction])
def history():
    return fetch_recent_history()


@app.get("/healthz")
def healthz():
    status = {"ollama": False, "postgres": False}
    try:
        with httpx.Client(timeout=5.0) as client:
            client.get(f"{OLLAMA_BASE_URL}/api/tags").raise_for_status()
        status["ollama"] = True
    except httpx.HTTPError:
        pass
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
        status["postgres"] = True
    except psycopg.Error:
        pass
    return status

import os
import httpx
from fastapi import HTTPException

OLLAMA_BASE_URL = os.environ["OLLAMA_BASE_URL"]
OLLAMA_MODEL = os.environ["OLLAMA_MODEL"]
OLLAMA_URL = f"{OLLAMA_BASE_URL}/api/chat"
SYSTEM_PROMPT = (
    "You are a concise, helpful assistant. "
    "Answer in one short paragraph (under 80 words). "
    "If you don't know, say so plainly."
)


def call_ollama(question: str) -> str:
    try:
        with httpx.Client(timeout=60.0) as client:
            r = client.post(OLLAMA_URL, json={
                "model": OLLAMA_MODEL,
                "messages": [
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": question},
                ],
                "stream": False,
            })
            r.raise_for_status()
            return r.json()["message"]["content"]
    except httpx.HTTPError:
        raise HTTPException(status_code=502, detail="Ollama is not reachable.")

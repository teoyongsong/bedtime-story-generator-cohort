import os
from google import genai
from google.genai import types
from google.genai import errors as genai_errors
from fastapi import HTTPException

GEMINI_API_KEY = os.environ["GEMINI_API_KEY"]
GEMINI_MODEL = "gemini-2.5-flash-lite"
SYSTEM_PROMPT = (
    "You are a concise, helpful assistant. "
    "Answer in one short paragraph (under 80 words). "
    "If you don't know, say so plainly."
)

client = genai.Client(api_key=GEMINI_API_KEY)
generate_config = types.GenerateContentConfig(system_instruction=SYSTEM_PROMPT)


def call_gemini(question: str) -> str:
    try:
        response = client.models.generate_content(
            model=GEMINI_MODEL,
            contents=question,
            config=generate_config,
        )
        return response.text
    except genai_errors.APIError:
        raise HTTPException(status_code=502, detail="Gemini is not reachable.")

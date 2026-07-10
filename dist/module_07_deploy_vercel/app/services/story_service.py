import psycopg
from psycopg.rows import dict_row
from fastapi import HTTPException

from app.database import get_conn
from app.schemas import StoredStory, StoryRequest
from app.services.gemini_service import GEMINI_MODEL


def save_story(req: StoryRequest, body: str) -> int:
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO stories "
                    "(child_name, characters, setting, plot, body, model_name) "
                    "VALUES (%s, %s, %s, %s, %s, %s) RETURNING id",
                    (
                        req.child_name.strip(),
                        req.characters.strip(),
                        req.setting.strip(),
                        req.plot.strip(),
                        body,
                        GEMINI_MODEL,
                    ),
                )
                story_id = cur.fetchone()[0]
            conn.commit()
            return story_id
    except psycopg.Error:
        raise HTTPException(
            status_code=502,
            detail="Postgres is not reachable. Check your database connection.",
        )


def fetch_recent_stories(child_name: str, limit: int = 5) -> list[StoredStory]:
    with get_conn() as conn:
        with conn.cursor(row_factory=dict_row) as cur:
            cur.execute(
                "SELECT id, child_name, characters, setting, plot, body, model_name, "
                "       to_char(created_at, 'YYYY-MM-DD HH24:MI:SS') AS created_at "
                "FROM stories WHERE child_name = %s "
                "ORDER BY created_at DESC LIMIT %s",
                (child_name.strip(), limit),
            )
            return [StoredStory(**row) for row in cur.fetchall()]

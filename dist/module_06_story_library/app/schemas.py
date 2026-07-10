from pydantic import BaseModel


class StoryRequest(BaseModel):
    child_name: str
    characters: str
    setting: str
    plot: str


class StoryResponse(BaseModel):
    story: str


class StoredStory(BaseModel):
    id: int
    child_name: str
    characters: str
    setting: str
    plot: str
    body: str
    model_name: str
    created_at: str

from pydantic import BaseModel


class StoryRequest(BaseModel):
    child_name: str
    characters: str
    setting: str
    plot: str


class StoryResponse(BaseModel):
    story: str

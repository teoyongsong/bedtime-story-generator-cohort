from app.schemas import StoryRequest


def compose_story_prompt(req: StoryRequest) -> str:
    return (
        f"Write a short bedtime story for a child named {req.child_name.strip()}.\n"
        f"\n"
        f"Characters: {req.characters.strip()}\n"
        f"Setting: {req.setting.strip()}\n"
        f"Plot: {req.plot.strip()}\n"
    )

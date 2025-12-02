from pydantic import BaseModel, Field


class EnrollQuestRequest(BaseModel):
    """Request to enroll an adventurer in a quest."""
    
    quest_id: str = Field(..., alias="questId", description="The unique identifier of the quest to enroll in")
    adventurer_name: str = Field(..., alias="adventurerName", description="The name of the adventurer enrolling in the quest")
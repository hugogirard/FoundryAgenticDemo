from pydantic import BaseModel, Field


class CompleteQuestRequest(BaseModel):
    """Request to mark a quest as completed."""
    
    enrollment_id: str = Field(..., alias="enrollmentId", description="The unique identifier of the quest enrollment to complete")
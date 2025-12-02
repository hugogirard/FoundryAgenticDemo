from pydantic import BaseModel, Field
from datetime import datetime
from enum import Enum
from typing import Optional


class QuestStatus(str, Enum):
    """Status of an adventurer's quest enrollment."""
    IN_PROGRESS = "InProgress"
    COMPLETED = "Completed"
    FAILED = "Failed"
    ABANDONED = "Abandoned"


class QuestEnrollment(BaseModel):
    """Represents an adventurer's enrollment in a Mage Guild quest."""
    
    id: str = Field(..., description="Unique identifier for the quest enrollment")
    quest_id: str = Field(..., alias="questId", description="Reference to the Quest ID that the adventurer is enrolled in")
    adventurer_name: str = Field(..., alias="adventurerName", description="Name of the adventurer who enrolled in the quest")
    enrolled_date: datetime = Field(..., alias="enrolledDate", description="Date and time when the adventurer accepted the quest")
    status: QuestStatus = Field(..., description="Current status of the quest (InProgress, Completed, Failed, or Abandoned)")
    completed_date: Optional[datetime] = Field(None, alias="completedDate", description="Date and time when the quest was completed, failed, or abandoned")
    reward_claimed: bool = Field(..., alias="rewardClaimed", description="Whether the adventurer has claimed their reward for completing the quest")
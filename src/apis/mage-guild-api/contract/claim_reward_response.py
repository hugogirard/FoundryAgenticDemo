from pydantic import BaseModel, Field


class ClaimRewardResponse(BaseModel):
    """Response returned when an adventurer claims their quest reward."""
    
    success: bool = Field(..., description="Indicates whether the reward claim was successful")
    message: str = Field(..., description="Descriptive message about the reward claim result")
    gold_received: int = Field(..., alias="goldReceived", description="Amount of gold the adventurer received")
    item_received: str = Field(..., alias="itemReceived", description="Name of the item the adventurer received")
from pydantic import BaseModel, Field

class Quest(BaseModel):
    """Represents a quest available from the Mage Guild in Skyrim."""
    
    id: str = Field(..., description="Unique identifier for the quest")
    title: str = Field(..., description="The name of the quest as displayed in the journal")
    description: str = Field(..., description="Detailed description of the quest objectives and background story")
    difficulty: str = Field(..., description="Quest difficulty level (e.g., 'Novice', 'Apprentice', 'Adept', 'Expert', 'Master')")
    reward_gold: int = Field(..., alias="rewardGold", description="Amount of gold awarded upon quest completion")
    reward_item: str = Field(..., alias="rewardItem", description="Special item or equipment rewarded for completing the quest")
    is_available: bool = Field(..., alias="isAvailable", description="Whether the quest is currently available to accept")
    location: str = Field(..., description="Primary location where the quest takes place (e.g., 'College of Winterhold', 'Saarthal')")
    quest_giver: str = Field(..., alias="questGiver", description="NPC who assigns the quest (e.g., 'Arch-Mage Savos Aren', 'Tolfdir')")
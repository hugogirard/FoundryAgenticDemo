import json
import uuid
from datetime import datetime
from pathlib import Path
from typing import List, Optional

from models.quest import Quest
from models.quest_enrollment import QuestEnrollment, QuestStatus


class QuestRepository:
    """In-memory repository for managing quests and quest enrollments."""
    
    def __init__(self, json_path: Optional[str] = None):
        """
        Initialize the repository and load quests from JSON file.
        
        Args:
            json_path: Path to the quests.json file. If None, defaults to Data/quests.json
        """
        self._enrollments: List[QuestEnrollment] = []
        
        if json_path is None:
            json_path = Path(__file__).parent.parent / "data" / "quests.json"
        else:
            json_path = Path(json_path)
        
        self._json_path = json_path
        self._load_quests()
    
    def _load_quests(self):
        """Load quests from the JSON file."""
        with open(self._json_path, 'r') as f:
            quests_data = json.load(f)
            self._quests = [Quest(**quest) for quest in quests_data]
    
    async def get_available_quests_async(self) -> List[Quest]:
        """
        Get all quests that are currently available.
        
        Returns:
            List of available quests
        """
        return [q for q in self._quests if q.is_available]
    
    async def get_quest_by_id_async(self, quest_id: str) -> Optional[Quest]:
        """
        Get a specific quest by its ID.
        
        Args:
            quest_id: The unique identifier of the quest
            
        Returns:
            The quest if found, None otherwise
        """
        return next((q for q in self._quests if q.id == quest_id), None)
    
    async def enroll_in_quest_async(self, quest_id: str, adventurer_name: str) -> Optional[QuestEnrollment]:
        """
        Enroll an adventurer in a quest.
        
        Args:
            quest_id: The ID of the quest to enroll in
            adventurer_name: The name of the adventurer
            
        Returns:
            The quest enrollment if successful, None if quest is unavailable or adventurer is already enrolled
        """
        quest = next((q for q in self._quests if q.id == quest_id), None)
        if quest is None or not quest.is_available:
            return None
        
        # Check if adventurer is already enrolled in this quest with InProgress status
        existing_enrollment = next(
            (e for e in self._enrollments 
             if e.quest_id == quest_id 
             and e.adventurer_name == adventurer_name 
             and e.status == QuestStatus.IN_PROGRESS),
            None
        )
        
        if existing_enrollment is not None:
            return None
        
        enrollment = QuestEnrollment(
            id=f"enrollment-{uuid.uuid4()}",
            quest_id=quest_id,
            adventurer_name=adventurer_name,
            enrolled_date=datetime.utcnow(),
            status=QuestStatus.IN_PROGRESS,
            completed_date=None,
            reward_claimed=False
        )
        
        self._enrollments.append(enrollment)
        return enrollment
    
    async def get_enrollments_by_adventurer_async(self, adventurer_name: str) -> List[QuestEnrollment]:
        """
        Get all quest enrollments for a specific adventurer.
        
        Args:
            adventurer_name: The name of the adventurer
            
        Returns:
            List of quest enrollments for the adventurer
        """
        return [e for e in self._enrollments if e.adventurer_name == adventurer_name]
    
    async def get_enrollment_by_id_async(self, enrollment_id: str) -> Optional[QuestEnrollment]:
        """
        Get a specific enrollment by its ID.
        
        Args:
            enrollment_id: The unique identifier of the enrollment
            
        Returns:
            The enrollment if found, None otherwise
        """
        return next((e for e in self._enrollments if e.id == enrollment_id), None)
    
    async def complete_quest_async(self, enrollment_id: str) -> bool:
        """
        Mark a quest enrollment as completed.
        
        Args:
            enrollment_id: The ID of the enrollment to complete
            
        Returns:
            True if successful, False if enrollment not found or not in progress
        """
        enrollment = next((e for e in self._enrollments if e.id == enrollment_id), None)
        if enrollment is None or enrollment.status != QuestStatus.IN_PROGRESS:
            return False
        
        # Update the enrollment
        index = self._enrollments.index(enrollment)
        self._enrollments[index] = QuestEnrollment(
            id=enrollment.id,
            quest_id=enrollment.quest_id,
            adventurer_name=enrollment.adventurer_name,
            enrolled_date=enrollment.enrolled_date,
            status=QuestStatus.COMPLETED,
            completed_date=datetime.utcnow(),
            reward_claimed=enrollment.reward_claimed
        )
        return True
    
    async def claim_reward_async(self, enrollment_id: str) -> bool:
        """
        Claim the reward for a completed quest.
        
        Args:
            enrollment_id: The ID of the enrollment to claim reward for
            
        Returns:
            True if successful, False if enrollment not found, not completed, or reward already claimed
        """
        enrollment = next((e for e in self._enrollments if e.id == enrollment_id), None)
        if (enrollment is None or 
            enrollment.status != QuestStatus.COMPLETED or 
            enrollment.reward_claimed):
            return False
        
        # Update the enrollment
        index = self._enrollments.index(enrollment)
        self._enrollments[index] = QuestEnrollment(
            id=enrollment.id,
            quest_id=enrollment.quest_id,
            adventurer_name=enrollment.adventurer_name,
            enrolled_date=enrollment.enrolled_date,
            status=enrollment.status,
            completed_date=enrollment.completed_date,
            reward_claimed=True
        )
        return True
    
    async def reset_all_data_async(self) -> None:
        """
        Reset all in-memory data: clear all enrollments and reload quests from the JSON file.
        This effectively resets the repository to its initial state.
        """
        self._enrollments.clear()
        self._load_quests()
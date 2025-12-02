from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from logging import Logger

from models import Quest, QuestEnrollment
from contract import EnrollQuestRequest, CompleteQuestRequest, ClaimRewardResponse
from repositories import QuestRepository
from dependencies import get_quest_repository, get_logger

router = APIRouter(
    prefix="/api/quests",
    tags=["Quests"]
)


@router.get(
    "/",
    response_model=List[Quest],
    summary="Get all available quests in the Mage Guild",
    name="GetAvailableQuests"
)
async def get_available_quests(
    repository: QuestRepository = Depends(get_quest_repository),
    logger: Logger = Depends(get_logger)
):
    """Get all quests that are currently available for adventurers."""
    logger.info("Fetching all available quests")
    quests = await repository.get_available_quests_async()
    logger.info(f"Found {len(quests)} available quests")
    return quests


@router.get(
    "/{quest_id}",
    response_model=Quest,
    summary="Get details of a specific quest",
    name="GetQuestById"
)
async def get_quest_by_id(
    quest_id: str,
    repository: QuestRepository = Depends(get_quest_repository),
    logger: Logger = Depends(get_logger)
):
    """Get detailed information about a specific quest by its ID."""
    logger.info(f"Fetching quest with ID: {quest_id}")
    quest = await repository.get_quest_by_id_async(quest_id)
    if quest is None:
        logger.warning(f"Quest not found: {quest_id}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Quest not found"
        )
    logger.info(f"Quest found: {quest.title}")
    return quest


@router.post(
    "/enroll",
    response_model=QuestEnrollment,
    status_code=status.HTTP_201_CREATED,
    summary="Enroll an adventurer in a quest",
    name="EnrollInQuest"
)
async def enroll_in_quest(
    request: EnrollQuestRequest,
    repository: QuestRepository = Depends(get_quest_repository),
    logger: Logger = Depends(get_logger)
):
    """Enroll an adventurer in a specific quest."""
    logger.info(f"Enrolling adventurer '{request.adventurer_name}' in quest '{request.quest_id}'")
    
    quest = await repository.get_quest_by_id_async(request.quest_id)
    if quest is None:
        logger.warning(f"Quest not found for enrollment: {request.quest_id}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Quest not found"
        )
    
    enrollment = await repository.enroll_in_quest_async(
        request.quest_id,
        request.adventurer_name
    )
    
    if enrollment is None:
        logger.warning(f"Failed to enroll '{request.adventurer_name}' in quest '{request.quest_id}'")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unable to enroll in quest. You may already be enrolled in this quest."
        )
    
    logger.info(f"Successfully enrolled '{request.adventurer_name}' in quest '{quest.title}'. Enrollment ID: {enrollment.id}")
    return enrollment


@router.get(
    "/enrollments/{adventurer_name}",
    response_model=List[QuestEnrollment],
    summary="Get all quest enrollments for an adventurer",
    name="GetAdventurerEnrollments"
)
async def get_adventurer_enrollments(
    adventurer_name: str,
    repository: QuestRepository = Depends(get_quest_repository),
    logger: Logger = Depends(get_logger)
):
    """Get all quest enrollments for a specific adventurer."""
    logger.info(f"Fetching enrollments for adventurer: {adventurer_name}")
    enrollments = await repository.get_enrollments_by_adventurer_async(adventurer_name)
    logger.info(f"Found {len(enrollments)} enrollments for '{adventurer_name}'")
    return enrollments


@router.post(
    "/complete",
    summary="Mark a quest as completed",
    name="CompleteQuest"
)
async def complete_quest(
    request: CompleteQuestRequest,
    repository: QuestRepository = Depends(get_quest_repository),
    logger: Logger = Depends(get_logger)
):
    """Mark a quest enrollment as completed."""
    logger.info(f"Attempting to complete quest enrollment: {request.enrollment_id}")
    
    enrollment = await repository.get_enrollment_by_id_async(request.enrollment_id)
    if enrollment is None:
        logger.warning(f"Enrollment not found: {request.enrollment_id}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Enrollment not found"
        )
    
    success = await repository.complete_quest_async(request.enrollment_id)
    if not success:
        logger.warning(f"Failed to complete quest enrollment: {request.enrollment_id}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Quest cannot be completed. It may already be completed or abandoned."
        )
    
    logger.info(f"Quest completed successfully for enrollment: {request.enrollment_id}")
    return {
        "message": "Quest completed successfully!",
        "enrollmentId": request.enrollment_id
    }


@router.post(
    "/claim-reward/{enrollment_id}",
    response_model=ClaimRewardResponse,
    summary="Claim the reward for a completed quest",
    name="ClaimReward"
)
async def claim_reward(
    enrollment_id: str,
    repository: QuestRepository = Depends(get_quest_repository),
    logger: Logger = Depends(get_logger)
):
    """Claim the reward for a completed quest enrollment."""
    logger.info(f"Attempting to claim reward for enrollment: {enrollment_id}")
    
    enrollment = await repository.get_enrollment_by_id_async(enrollment_id)
    if enrollment is None:
        logger.warning(f"Enrollment not found: {enrollment_id}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Enrollment not found"
        )
    
    quest = await repository.get_quest_by_id_async(enrollment.quest_id)
    if quest is None:
        logger.warning(f"Quest not found for enrollment: {enrollment_id}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Quest not found"
        )
    
    success = await repository.claim_reward_async(enrollment_id)
    if not success:
        logger.warning(f"Failed to claim reward for enrollment: {enrollment_id}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot claim reward. Quest may not be completed or reward already claimed."
        )
    
    logger.info(f"Reward claimed successfully for enrollment: {enrollment_id}. Gold: {quest.reward_gold}, Item: {quest.reward_item}")
    return ClaimRewardResponse(
        success=True,
        message="Reward claimed successfully!",
        gold_received=quest.reward_gold,
        item_received=quest.reward_item
    )


@router.post(
    "/reset",
    status_code=status.HTTP_200_OK,
    summary="Reset all in-memory data",
    name="ResetData"
)
async def reset_data(
    repository: QuestRepository = Depends(get_quest_repository),
    logger: Logger = Depends(get_logger)
):
    """Reset all in-memory data: clears all quest enrollments and reloads quests from the original JSON file."""
    logger.info("Resetting all in-memory data")
    await repository.reset_all_data_async()
    logger.info("All data has been reset successfully")
    return {
        "success": True,
        "message": "All in-memory data has been reset successfully. All enrollments have been cleared and quests have been reloaded."
    }
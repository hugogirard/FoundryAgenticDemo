import { BadRequestException, Body, Controller, Get, NotFoundException, Param, Post } from '@nestjs/common';
import { QuestRepository } from './quest.repository';
import { Quest } from 'src/models/quest';
import { ApiBody, ApiOperation, ApiParam, ApiResponse, ApiTags } from '@nestjs/swagger'
import { Enrollement } from 'src/payload/enrollment';
import { QuestEnrollement } from 'src/models/quest.enrollement';


@ApiTags('Quest Management')
@Controller('api/quest')
export class QuestController {

    constructor(private questRepository: QuestRepository) {

    }

    @Get('all')
    @ApiOperation({
        summary: 'Retrieve all available quests',
        description: 'Fetches a complete list of all currently available quests from the mage guild. Only returns quests that are not currently enrolled by any adventurer and are ready to be taken.'
    })
    @ApiResponse({
        status: 200,
        description: 'Successfully retrieved the list of available quests',
        type: [Quest]
    })
    getAvailableQuest(): Array<Quest> {
        return this.questRepository.getAvailableQuests();
    }

    @Get(':id')
    @ApiOperation({
        summary: 'Retrieve a specific quest by ID',
        description: 'Fetches detailed information about a specific quest using its unique identifier. Returns quest details including title, description, difficulty, rewards, and availability status.'
    })
    @ApiParam({
        name: 'id',
        description: 'Unique identifier of the quest to retrieve'
    })
    @ApiResponse({
        status: 200,
        description: 'Quest successfully found and returned',
        type: Quest
    })
    @ApiResponse({
        status: 404,
        description: 'Quest with the specified ID was not found'
    })
    getQuestById(@Param('id') id: string): Quest | undefined {
        const quest = this.questRepository.getQuestById(id);

        if (quest === null) {
            throw new NotFoundException(`Quest with id ${id} not found`);
        }

        return quest;
    }

    @Get('/enrolled/:adventurerName')
    @ApiOperation({
        summary: 'Retrieve all quests enrolled by an adventurer',
        description: 'Fetches a complete list of all quests that a specific adventurer has enrolled in. Includes quest enrollment details such as enrollment date, current status (in-progress, completed), and reward claim status.'
    })
    @ApiParam({
        name: 'adventurerName',
        description: 'Name of the adventurer whose enrolled quests to retrieve'
    })
    @ApiResponse({
        status: 200,
        description: 'Successfully retrieved list of enrolled quests for the adventurer',
        type: [QuestEnrollement]
    })
    getQuestEnrolled(@Param('adventurerName') adventurerName: string): Array<QuestEnrollement> {
        return this.questRepository.questByAdventurers(adventurerName);
    }

    @Post('enroll')
    @ApiOperation({
        summary: 'Enroll an adventurer in a quest',
        description: 'Allows an adventurer to enroll in an available quest from the mage guild. The quest must be available and not currently taken by another adventurer. Upon successful enrollment, the quest becomes unavailable to others and an enrollment record is created with in-progress status.'
    })
    @ApiBody({
        type: Enrollement,
        description: 'Enrollment details including quest ID and adventurer name'
    })
    @ApiResponse({
        status: 201,
        description: 'Successfully enrolled in the quest',
        type: QuestEnrollement
    })
    @ApiResponse({
        status: 400,
        description: 'Quest is not available or enrollment failed'
    })
    enrollIntoQuest(@Body() enrollement: Enrollement): QuestEnrollement | undefined {

        const questEnrollement = this.questRepository.takeQuestById(enrollement.questId, enrollement.adventurerName);

        if (questEnrollement === null) {
            throw new BadRequestException(`The quest ${enrollement.questId} for adventurer ${enrollement.adventurerName} cannot be taken`);
        }

        return questEnrollement;
    }

    @Post('cancel')
    @ApiOperation({
        summary: 'Cancel an enrolled quest',
        description: 'Allows an adventurer to cancel their enrollment in a quest. This removes the enrollment record and makes the quest available again for other adventurers to take. Use this when an adventurer decides not to continue with a quest they previously enrolled in.'
    })
    @ApiBody({
        type: Enrollement,
        description: 'Quest cancellation details including quest ID and adventurer name'
    })
    @ApiResponse({
        status: 200,
        description: 'Quest enrollment successfully cancelled'
    })
    @ApiResponse({
        status: 404,
        description: 'Quest enrollment not found'
    })
    cancelQuest(@Body() enrollement: Enrollement) {
        this.questRepository.cancelQuest(enrollement.questId, enrollement.adventurerName);
    }

    @Post('complete')
    @ApiOperation({
        summary: 'Mark a quest as completed',
        description: 'Marks an enrolled quest as completed by an adventurer. This updates the quest status to completed, records the completion date, and marks rewards as claimed. The quest can only be completed if the adventurer has an active enrollment for it.'
    })
    @ApiBody({
        type: Enrollement,
        description: 'Quest completion details including quest ID and adventurer name'
    })
    @ApiResponse({
        status: 200,
        description: 'Quest successfully completed',
        type: QuestEnrollement
    })
    @ApiResponse({
        status: 400,
        description: 'Quest cannot be completed - enrollment not found or invalid state'
    })
    completeQuest(@Body() enrollement: Enrollement) {
        const quest = this.questRepository.completeQuest(enrollement.questId, enrollement.adventurerName);

        if (quest === null) {
            throw new BadRequestException(`The quest ${enrollement.questId} for adventurer ${enrollement.adventurerName} cannot be completed`);
        }

        return quest;
    }


}

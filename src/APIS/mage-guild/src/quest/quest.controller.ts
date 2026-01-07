import { BadRequestException, Body, Controller, Get, NotFoundException, Param, Post } from '@nestjs/common';
import { QuestRepository } from './quest.repository';
import type { Quest } from 'src/models/quest';
import { ApiBody, ApiOperation } from '@nestjs/swagger'
import { Enrollement } from 'src/payload/enrollment';
import { QuestEnrollement } from 'src/models/quest.enrollement';


@Controller('api/quest')
export class QuestController {

    constructor(private questRepository: QuestRepository) {

    }

    @Get('all')
    @ApiOperation({
        summary: 'Retrieve all quests',
        description: 'Retrieve all available quests from the mage guild'
    })
    getAvailableQuest(): Array<Quest> {
        return this.questRepository.getAvailableQuests();
    }

    @Get(':id')
    @ApiOperation({
        summary: 'Retrieve speficic quest',
        description: 'Retrieve specific quest by id from the mage guild'
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
        summary: 'Retrieve quests enrolled for a specific adventurer',
        description: 'Retrieve quests enrolled for a specific adventurer'
    })
    getQuestEnrolled(@Param('adventurerName') adventurerName: string): Array<QuestEnrollement> {
        return this.questRepository.questByAdventurers(adventurerName);
    }

    @Post('enroll')
    @ApiOperation({
        summary: 'Enroll to mage quest',
        description: 'Enroll to a mage guild quest'
    })
    @ApiBody({
        type: Enrollement
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
        description: 'Cancel a quest enrolled by an adventurer to the mage guild quest'
    })
    @ApiBody({
        type: Enrollement
    })
    cancelQuest(@Body() enrollement: Enrollement) {
        this.questRepository.cancelQuest(enrollement.questId, enrollement.adventurerName);
    }

    @Post('complete')
    @ApiOperation({
        summary: 'Complete an enrolled quest',
        description: 'Complete a quest enrolled by an adventurer to the mage guild quest'
    })
    @ApiBody({
        type: Enrollement
    })
    completeQuest(@Body() enrollement: Enrollement) {
        const quest = this.questRepository.completeQuest(enrollement.questId, enrollement.adventurerName);

        if (quest === null) {
            throw new BadRequestException(`The quest ${enrollement.questId} for adventurer ${enrollement.adventurerName} cannot be completed`);
        }

        return quest;
    }


}

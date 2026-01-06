import { Controller, Get, NotFoundException, Param } from '@nestjs/common';
import { QuestRepository } from './quest.repository';
import type { Quest } from 'src/models/quest';
import { ApiOperation } from '@nestjs/swagger'


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
    getQuestById(@Param('id') id: string): Quest {
        const quest = this.questRepository.getQuestById(id);

        if (quest === null) {
            throw new NotFoundException(`Quest with id ${id} not found`);
        }

        return quest;
    }

}

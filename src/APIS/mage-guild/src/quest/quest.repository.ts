import { Injectable } from '@nestjs/common';
import { Quest } from 'src/models/quest';
// eslint-disable-next-line @typescript-eslint/no-require-imports, @typescript-eslint/no-unsafe-assignment
const questData = require('../data/quest.json');

@Injectable()
export class QuestRepository {

    private quests: Array<Quest>

    constructor() {
        // eslint-disable-next-line @typescript-eslint/no-require-imports, @typescript-eslint/no-unsafe-assignment
        this.quests = questData;
    }

    getAvailableQuests(): Array<Quest> {
        return this.quests.filter(q => q.isAvailable === true);
    }

    getQuestById(id: string): Quest | null {
        const idx = this.quests.findIndex(q => q.id === id);

        if (idx !== -1) {
            return this.quests[idx];
        }

        return null;
    }
}

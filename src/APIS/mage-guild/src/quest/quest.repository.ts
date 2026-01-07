import { Injectable } from '@nestjs/common';
import { Quest } from 'src/models/quest';
import { QuestEnrollement, QuestStatus } from 'src/models/quest.enrollement';
import { quests } from 'src/data/quest';

@Injectable()
export class QuestRepository {

    private quests: Array<Quest>
    private questEnrollements: Array<QuestEnrollement>;

    constructor() {
        this.quests = quests;
        this.questEnrollements = [];
    }

    getAvailableQuests(): Array<Quest> {
        return this.quests.filter(q => q.isAvailable === true);
    }

    getQuestById(id: string): Quest | undefined {
        const quest = this.quests.find(q => q.id === id);
        return quest;
    }

    takeQuestById(id: string, adventurerName: string): QuestEnrollement | null {
        const index = this.quests.findIndex(q => q.id === id);

        if (index !== -1) {
            const quest = this.quests[index];
            quest.isAvailable = false;
            this.quests[index] = quest;
            const enrollmentId = `${quest.id}-${adventurerName}-${Date.now()}`;
            const enrollment: QuestEnrollement = {
                id: enrollmentId,
                questId: quest.id,
                adventurerName: adventurerName,
                enrolledDate: new Date().toISOString(),
                status: QuestStatus.InProgress,
                completeDate: '',
                rewardClaimed: false
            };
            this.questEnrollements.push(enrollment);
            return enrollment;
        }

        return null
    }
}

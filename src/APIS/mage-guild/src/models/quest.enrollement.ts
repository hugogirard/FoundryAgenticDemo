

export class QuestEnrollement {
    id: string;
    questId: string;
    adventurerName: string;
    enrolledDate: string;
    status: QuestStatus;
    completeDate: string;
    rewardClaimed: boolean;

}

export enum QuestStatus {
    InProgress = 1,
    Completed,
    Failed,
    Abandoned
}
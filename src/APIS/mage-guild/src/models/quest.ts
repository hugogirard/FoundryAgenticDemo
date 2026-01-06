
export interface Quest {
    id: string;
    title: string;
    description: string;
    difficulty: string;
    rewardGold: number;
    rewardItem: string;
    location: string;
    questGiver: string;
    isAvailable: boolean;
}
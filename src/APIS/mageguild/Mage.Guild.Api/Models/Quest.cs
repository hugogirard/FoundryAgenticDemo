namespace Mage.Guild.Api.Models;

public record Quest(
    string Id,
    string Title,
    string Description,
    string Difficulty,
    int RewardGold,
    string RewardItem,
    bool IsAvailable,
    string Location,
    string QuestGiver
);

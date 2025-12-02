namespace Mage.Guild.Api.Models;

public record QuestEnrollment(
    string Id,
    string QuestId,
    string AdventurerName,
    DateTime EnrolledDate,
    QuestStatus Status,
    DateTime? CompletedDate,
    bool RewardClaimed
);

public enum QuestStatus
{
    InProgress,
    Completed,
    Failed,
    Abandoned
}

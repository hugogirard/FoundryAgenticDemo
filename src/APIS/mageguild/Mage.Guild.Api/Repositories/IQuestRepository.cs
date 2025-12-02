using Mage.Guild.Api.Models;

namespace Mage.Guild.Api.Repositories;

public interface IQuestRepository
{
    Task<IEnumerable<Quest>> GetAvailableQuestsAsync();
    Task<Quest?> GetQuestByIdAsync(string questId);
    Task<QuestEnrollment?> EnrollInQuestAsync(string questId, string adventurerName);
    Task<IEnumerable<QuestEnrollment>> GetEnrollmentsByAdventurerAsync(string adventurerName);
    Task<QuestEnrollment?> GetEnrollmentByIdAsync(string enrollmentId);
    Task<bool> CompleteQuestAsync(string enrollmentId);
    Task<bool> ClaimRewardAsync(string enrollmentId);
}

using Mage.Guild.Api.Models;
using System.Text.Json;

namespace Mage.Guild.Api.Repositories;

public class InMemoryQuestRepository : IQuestRepository
{
    private readonly List<Quest> _quests;
    private readonly List<QuestEnrollment> _enrollments = [];

    public InMemoryQuestRepository()
    {
        var jsonPath = Path.Combine(AppContext.BaseDirectory, "Data", "quests.json");
        var jsonContent = File.ReadAllText(jsonPath);
        _quests = JsonSerializer.Deserialize<List<Quest>>(jsonContent, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        }) ?? [];
    }

    public Task<IEnumerable<Quest>> GetAvailableQuestsAsync()
    {
        return Task.FromResult(_quests.Where(q => q.IsAvailable).AsEnumerable());
    }

    public Task<Quest?> GetQuestByIdAsync(string questId)
    {
        return Task.FromResult(_quests.FirstOrDefault(q => q.Id == questId));
    }

    public Task<QuestEnrollment?> EnrollInQuestAsync(string questId, string adventurerName)
    {
        var quest = _quests.FirstOrDefault(q => q.Id == questId);
        if (quest == null || !quest.IsAvailable)
        {
            return Task.FromResult<QuestEnrollment?>(null);
        }

        var existingEnrollment = _enrollments.FirstOrDefault(e => 
            e.QuestId == questId && 
            e.AdventurerName == adventurerName && 
            e.Status == QuestStatus.InProgress);

        if (existingEnrollment != null)
        {
            return Task.FromResult<QuestEnrollment?>(null);
        }

        var enrollment = new QuestEnrollment(
            Id: $"enrollment-{Guid.NewGuid()}",
            QuestId: questId,
            AdventurerName: adventurerName,
            EnrolledDate: DateTime.UtcNow,
            Status: QuestStatus.InProgress,
            CompletedDate: null,
            RewardClaimed: false
        );

        _enrollments.Add(enrollment);
        return Task.FromResult<QuestEnrollment?>(enrollment);
    }

    public Task<IEnumerable<QuestEnrollment>> GetEnrollmentsByAdventurerAsync(string adventurerName)
    {
        return Task.FromResult(_enrollments.Where(e => e.AdventurerName == adventurerName).AsEnumerable());
    }

    public Task<QuestEnrollment?> GetEnrollmentByIdAsync(string enrollmentId)
    {
        return Task.FromResult(_enrollments.FirstOrDefault(e => e.Id == enrollmentId));
    }

    public Task<bool> CompleteQuestAsync(string enrollmentId)
    {
        var enrollment = _enrollments.FirstOrDefault(e => e.Id == enrollmentId);
        if (enrollment == null || enrollment.Status != QuestStatus.InProgress)
        {
            return Task.FromResult(false);
        }

        var updatedEnrollment = enrollment with
        {
            Status = QuestStatus.Completed,
            CompletedDate = DateTime.UtcNow
        };

        var index = _enrollments.IndexOf(enrollment);
        _enrollments[index] = updatedEnrollment;
        return Task.FromResult(true);
    }

    public Task<bool> ClaimRewardAsync(string enrollmentId)
    {
        var enrollment = _enrollments.FirstOrDefault(e => e.Id == enrollmentId);
        if (enrollment == null || 
            enrollment.Status != QuestStatus.Completed || 
            enrollment.RewardClaimed)
        {
            return Task.FromResult(false);
        }

        var updatedEnrollment = enrollment with { RewardClaimed = true };
        var index = _enrollments.IndexOf(enrollment);
        _enrollments[index] = updatedEnrollment;
        return Task.FromResult(true);
    }
}

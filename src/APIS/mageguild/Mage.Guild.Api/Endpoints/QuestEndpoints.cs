using Mage.Guild.Api.Models;
using Mage.Guild.Api.Payload;
using Mage.Guild.Api.Repositories;

namespace Mage.Guild.Api.Endpoints;

public static class QuestEndpoints
{
    public static void MapQuestEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/quests")
            .WithTags("Quests")
            .WithOpenApi();

        group.MapGet("/", GetAvailableQuests)
            .WithName("GetAvailableQuests")
            .WithSummary("Get all available quests in the Mage Guild");

        group.MapGet("/{questId}", GetQuestById)
            .WithName("GetQuestById")
            .WithSummary("Get details of a specific quest");

        group.MapPost("/enroll", EnrollInQuest)
            .WithName("EnrollInQuest")
            .WithSummary("Enroll an adventurer in a quest");

        group.MapGet("/enrollments/{adventurerName}", GetAdventurerEnrollments)
            .WithName("GetAdventurerEnrollments")
            .WithSummary("Get all quest enrollments for an adventurer");

        group.MapPost("/complete", CompleteQuest)
            .WithName("CompleteQuest")
            .WithSummary("Mark a quest as completed");

        group.MapPost("/claim-reward/{enrollmentId}", ClaimReward)
            .WithName("ClaimReward")
            .WithSummary("Claim the reward for a completed quest");
    }

    private static async Task<IResult> GetAvailableQuests(IQuestRepository repository)
    {
        var quests = await repository.GetAvailableQuestsAsync();
        return Results.Ok(quests);
    }

    private static async Task<IResult> GetQuestById(string questId, IQuestRepository repository)
    {
        var quest = await repository.GetQuestByIdAsync(questId);
        return quest == null ? Results.NotFound(new { message = "Quest not found" }) : Results.Ok(quest);
    }

    private static async Task<IResult> EnrollInQuest(EnrollQuestRequest request, IQuestRepository repository)
    {
        if (string.IsNullOrWhiteSpace(request.QuestId) || string.IsNullOrWhiteSpace(request.AdventurerName))
        {
            return Results.BadRequest(new { message = "QuestId and AdventurerName are required" });
        }

        var quest = await repository.GetQuestByIdAsync(request.QuestId);
        if (quest == null)
        {
            return Results.NotFound(new { message = "Quest not found" });
        }

        var enrollment = await repository.EnrollInQuestAsync(request.QuestId, request.AdventurerName);
        if (enrollment == null)
        {
            return Results.BadRequest(new { message = "Unable to enroll in quest. You may already be enrolled in this quest." });
        }

        return Results.Created($"/api/quests/enrollments/{enrollment.AdventurerName}", enrollment);
    }

    private static async Task<IResult> GetAdventurerEnrollments(string adventurerName, IQuestRepository repository)
    {
        if (string.IsNullOrWhiteSpace(adventurerName))
        {
            return Results.BadRequest(new { message = "AdventurerName is required" });
        }

        var enrollments = await repository.GetEnrollmentsByAdventurerAsync(adventurerName);
        return Results.Ok(enrollments);
    }

    private static async Task<IResult> CompleteQuest(CompleteQuestRequest request, IQuestRepository repository)
    {
        if (string.IsNullOrWhiteSpace(request.EnrollmentId))
        {
            return Results.BadRequest(new { message = "EnrollmentId is required" });
        }

        var enrollment = await repository.GetEnrollmentByIdAsync(request.EnrollmentId);
        if (enrollment == null)
        {
            return Results.NotFound(new { message = "Enrollment not found" });
        }

        var success = await repository.CompleteQuestAsync(request.EnrollmentId);
        if (!success)
        {
            return Results.BadRequest(new { message = "Quest cannot be completed. It may already be completed or abandoned." });
        }

        return Results.Ok(new { message = "Quest completed successfully!", enrollmentId = request.EnrollmentId });
    }

    private static async Task<IResult> ClaimReward(string enrollmentId, IQuestRepository repository)
    {
        if (string.IsNullOrWhiteSpace(enrollmentId))
        {
            return Results.BadRequest(new { message = "EnrollmentId is required" });
        }

        var enrollment = await repository.GetEnrollmentByIdAsync(enrollmentId);
        if (enrollment == null)
        {
            return Results.NotFound(new { message = "Enrollment not found" });
        }

        var quest = await repository.GetQuestByIdAsync(enrollment.QuestId);
        if (quest == null)
        {
            return Results.NotFound(new { message = "Quest not found" });
        }

        var success = await repository.ClaimRewardAsync(enrollmentId);
        if (!success)
        {
            return Results.BadRequest(new { message = "Cannot claim reward. Quest may not be completed or reward already claimed." });
        }

        var response = new ClaimRewardResponse(
            Success: true,
            Message: "Reward claimed successfully!",
            GoldReceived: quest.RewardGold,
            ItemReceived: quest.RewardItem
        );

        return Results.Ok(response);
    }
}

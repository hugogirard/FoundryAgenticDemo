namespace Mage.Guild.Api.Payload;

public record ClaimRewardResponse(
    bool Success,
    string Message,
    int GoldReceived,
    string ItemReceived
);

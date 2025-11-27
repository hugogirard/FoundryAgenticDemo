using Newtonsoft.Json;

namespace Crime.Models;

public record Crime(
    string id,
    string crimeName,
    string crimeType,
    string city,
    string suspectName,
    string reward,
    string description
);
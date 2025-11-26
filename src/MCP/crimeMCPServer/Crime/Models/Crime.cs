using Newtonsoft.Json;

namespace Crime.Models;

public record Crime(
    string id,
    string crime_name,
    string city,
    string suspect_name,
    string reward,
    string description
);
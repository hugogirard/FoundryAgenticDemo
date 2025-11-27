using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Extensions.Mcp;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Crime;

public class CrimeResearcher
{
    private readonly ILogger<CrimeResearcher> _logger;
    private readonly ICrimeRepository _crimeRepository;

    public CrimeResearcher(ILogger<CrimeResearcher> logger,
                           ICrimeRepository crimeRepository)
    {
        _logger = logger;
        _crimeRepository = crimeRepository;
    }

    [Function(name: "getCrime")]
    public async Task<IEnumerable<Models.Crime>> Run([McpToolTrigger("getCrime", "Get list of crimes in Skyrim")] ToolInvocationContext context,
                                                     [McpToolProperty("crimeType", "The type of crime committed.", isRequired: false)] string crimeType,
                                                     [McpToolProperty("crimeName", "The crime name committed.", isRequired: false)] string crimeName,
                                                     [McpToolProperty("city", "The city where the crime is committed.", isRequired: false)] string city,
                                                     [McpToolProperty("description", "The description of the crime", isRequired: false)] string description)
    {
        try
        {
            if (string.IsNullOrEmpty(crimeType) && string.IsNullOrEmpty(crimeName) && string.IsNullOrEmpty(city) && string.IsNullOrEmpty(description))
            {
                throw new Exception("No parameters was passed");
            }

            var crimes = await _crimeRepository.GetCrimesAsync(crimeType, crimeName, city, description);
            return crimes;
        }
        catch (Exception ex)
        {
            {
                _logger.LogError(ex.Message, ex);
                throw new Exception("An error occurred while retrieving crimes.");
            }
        }
    }
}

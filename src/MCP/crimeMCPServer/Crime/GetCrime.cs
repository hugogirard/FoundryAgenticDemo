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
    public async Task<IEnumerable<Models.Crime>> Run([McpToolTrigger("getCrime","Get list of crimes in Skyrim")] ToolInvocationContext context,
                                                     [McpToolProperty("city", "The city where the crime is committed.", isRequired: false)]string city,
                                                     [McpToolProperty("description", "The description of the crime", isRequired: true)] string description) 
    {
        try
        {
            var crimes = await _crimeRepository.GetCrimesAsync(city, description);
            return crimes;
        }
        catch
        {
            throw;
            //_logger.LogError(ex.Message, ex);
            //throw new Exception("An error occurred while retrieving crimes.");            
        }
    }
}

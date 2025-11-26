using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Azure.Cosmos;


namespace Crime.Repositories;

public class CrimeRepository : ICrimeRepository
{
    private readonly Container _container;

    public CrimeRepository()
    {
        var client = new CosmosClient(Environment.GetEnvironmentVariable("CosmosDBConnectionString"));
        var db = client.GetDatabase("skyrim");
        _container = db.GetContainer("crime");
    }

    public async Task<IEnumerable<Models.Crime>> GetCrimesAsync(string city, string description)
    {
        QueryDefinition query;

        if (!string.IsNullOrEmpty(city)) 
        {
            query = new QueryDefinition(query: "SELECT TOP 10 * FROM c WHERE FullTextContains(c.description, @description) AND c.city = @city")
                                .WithParameter("@description", description)
                                .WithParameter("@city",city);
        }
        else
        {
            query = new QueryDefinition(query: "SELECT TOP 10 * FROM c WHERE FullTextContains(c.description, @description)")
                                .WithParameter("@description", description);                                
        }
            
        var feeds = _container.GetItemQueryIterator<Models.Crime>(query);

        var crimes = new List<Models.Crime>();

        while (feeds.HasMoreResults)
        {
            var response = await feeds.ReadNextAsync();
            crimes.AddRange(response.Resource);
        }

        return crimes;
    }
}

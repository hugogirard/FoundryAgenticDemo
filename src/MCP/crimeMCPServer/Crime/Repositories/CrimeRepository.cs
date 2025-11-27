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

    public async Task<IEnumerable<Models.Crime>> GetCrimesAsync(string crimeType,string crimeName, string city, string description)
    {
        var query = CreateQuery(crimeType, crimeName, city, description);

        var feeds = _container.GetItemQueryIterator<Models.Crime>(query);

        var crimes = new List<Models.Crime>();

        while (feeds.HasMoreResults)
        {
            var response = await feeds.ReadNextAsync();
            crimes.AddRange(response.Resource);
        }

        return crimes;
    }

    private QueryDefinition CreateQuery(string crimeType, string crimeName, string city, string description) 
    {
        QueryDefinition query;
        
        var selectStmt = new StringBuilder();
        var parameters = new Dictionary<string, string>();
        bool hasCondition = false;

        selectStmt.Append("SELECT * FROM c WHERE");

        if (!string.IsNullOrEmpty(crimeType)) 
        {
            selectStmt.Append(" c.crimeType = @crimeType");
            parameters.Add("@crimeType", crimeType);
            hasCondition = true;
        }

        if (!string.IsNullOrEmpty(crimeName)) 
        {
            if (hasCondition) selectStmt.Append(" AND ");
            selectStmt.Append(" FullTextContains(c.crimeName, @crimeName) ");
            parameters.Add("@crimeName", crimeName);
            hasCondition = true;
        }

        if (!string.IsNullOrEmpty(city)) 
        {
            if (hasCondition) selectStmt.Append(" AND ");
            selectStmt.Append(" c.city = @city");
            parameters.Add("@city", city);
            hasCondition = true;
        }

        if (!string.IsNullOrEmpty(description))
        {
            if (hasCondition) selectStmt.Append(" AND ");
            selectStmt.Append(" FullTextContains(c.description, @description) ");
            parameters.Add("@description", description);
        }

        // Delete the last AND clause
        //selectStmt = selectStmt.Remove(selectStmt.Length - 1, 1);
        query = new QueryDefinition(selectStmt.ToString());

        foreach (var p in parameters) 
        {
            query.WithParameter(p.Key, p.Value);
        }

        return query;
    }
}

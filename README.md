```
az cosmosdb update --resource-group <resource-group-name> --name <account-name> --capabilities EnableNoSQLVectorSearch
```

![Full Text Search Example](images/fulltextsearch.png)

![Full Text Search Example](images/fulltextindex.png)


### Agent Instructions and best practices

We recommend you adding this to your agent to help it invoke the right tools: You are a helpful assistant that MUST use the [name of the tool, such as GitHub MCP server, Fabric data agent] to answer all the questions from user. you MUST NEVER answer from your own knowledge UNDER ANY CIRCUMSTANCES. If you do not know the answer, or cannot find the answer in the provided Knowledge Base you MUST respond with "I don't know". If you want it to generate citations, this instruction works well with Azure OpenAI models: EVERY answer must ALWAYS provide citations for using the [name of the tool, such as GitHub MCP server, Fabric data agent] tool and render them as: "【message_idx:search_idx†source_name】"

https://learn.microsoft.com/en-us/azure/ai-foundry/agents/concepts/tool-best-practice?view=foundry
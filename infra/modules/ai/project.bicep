param accountName string
param location string
param projectName string
param projectDescription string
param displayName string
param aiSearchName string
param cosmosDBName string
param azureStorageName string
param useAzureManagedResource bool

resource searchService 'Microsoft.Search/searchServices@2024-06-01-preview' existing = {
  name: aiSearchName
}
resource cosmosDBAccount 'Microsoft.DocumentDB/databaseAccounts@2024-12-01-preview' existing = {
  name: cosmosDBName
}
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: azureStorageName
}

resource account 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: accountName
  scope: resourceGroup()
}

resource projectOwnResource 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = if (!useAzureManagedResource) {
  parent: account
  name: projectName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: projectDescription
    displayName: displayName
  }

  resource project_connection_cosmosdb_account 'connections@2025-04-01-preview' = {
    name: cosmosDBName
    properties: {
      category: 'CosmosDB'
      target: cosmosDBAccount.properties.documentEndpoint
      authType: 'AAD'
      metadata: {
        ApiType: 'Azure'
        ResourceId: cosmosDBAccount.id
        location: cosmosDBAccount.location
      }
    }
  }

  resource project_connection_azure_storage 'connections@2025-04-01-preview' = {
    name: azureStorageName
    properties: {
      category: 'AzureStorageAccount'
      target: storageAccount.properties.primaryEndpoints.blob
      authType: 'AAD'
      metadata: {
        ApiType: 'Azure'
        ResourceId: storageAccount.id
        location: storageAccount.location
      }
    }
  }

  resource project_connection_azureai_search 'connections@2025-04-01-preview' = {
    name: aiSearchName
    properties: {
      category: 'CognitiveSearch'
      target: 'https://${aiSearchName}.search.windows.net'
      authType: 'AAD'
      metadata: {
        ApiType: 'Azure'
        ResourceId: searchService.id
        location: searchService.location
      }
    }
  }
}

resource projectAzureManagedResource 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = if (useAzureManagedResource) {
  parent: account
  name: projectName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: projectDescription
    displayName: displayName
  }
}

output projectName string = useAzureManagedResource ? projectAzureManagedResource.name : projectOwnResource.name
output projectId string = useAzureManagedResource ? projectAzureManagedResource.id : projectOwnResource.id
output projectPrincipalId string = useAzureManagedResource
  ? projectAzureManagedResource.identity.principalId
  : projectOwnResource.identity.principalId

#disable-next-line BCP053
output projectWorkspaceId string = useAzureManagedResource
  ? projectAzureManagedResource.properties.internalId
  : projectOwnResource.properties.internalId

// return the BYO connection names
output cosmosDBConnection string = cosmosDBName
output azureStorageConnection string = azureStorageName
output aiSearchConnection string = aiSearchName

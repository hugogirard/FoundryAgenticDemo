// Creates Azure dependent resources for Azure AI Agent Service standard agent setup

@description('Azure region of the deployment')
param location string

@description('The name of the AI Search resource')
param aiSearchName string

@description('Name of the storage account')
param azureStorageName string

@description('Name of the new Cosmos DB account')
param cosmosDBName string

var tags = {
  SecurityControl: 'Ignore'
  FoundryDependencies: 'Yes'
}

// CosmosDB creation
var cosmosDbRegion = location
resource cosmosDB 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' = {
  name: cosmosDBName
  location: cosmosDbRegion
  kind: 'GlobalDocumentDB'
  tags: tags
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    disableLocalAuth: true
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    publicNetworkAccess: 'Disabled'
    enableFreeTier: false
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
  }
}

// AI Search creation

resource aiSearch 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: aiSearchName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
  properties: {
    disableLocalAuth: false
    authOptions: { aadOrApiKey: { aadAuthFailureMode: 'http401WithBearerChallenge' } }
    encryptionWithCmk: {
      enforcement: 'Unspecified'
    }
    hostingMode: 'default'
    partitionCount: 1
    publicNetworkAccess: 'disabled'
    replicaCount: 1
    semanticSearch: 'disabled'
    networkRuleSet: {
      bypass: 'None'
      ipRules: []
    }
  }
  sku: {
    name: 'standard'
  }
}

// Storage creation
resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: azureStorageName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  tags: tags
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: []
    }
    allowSharedKeyAccess: false
  }
}

output aiSearchName string = aiSearch.name
output aiSearchID string = aiSearch.id
output aiSearchServiceResourceGroupName string = resourceGroup().name
output aiSearchServiceSubscriptionId string = subscription().subscriptionId

output azureStorageName string = storage.name
output azureStorageId string = storage.id
output azureStorageResourceGroupName string = resourceGroup().name
output azureStorageSubscriptionId string = subscription().subscriptionId

output cosmosDBName string = cosmosDB.name
output cosmosDBId string = cosmosDB.id
output cosmosDBResourceGroupName string = resourceGroup().name
output cosmosDBSubscriptionId string = subscription().subscriptionId

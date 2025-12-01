param location string
param aiSearchName string

var tags = {
  SecurityControl: 'Ignore'
}

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
    publicNetworkAccess: 'enabled'
    replicaCount: 1
  }
  sku: {
    name: 'standard'
  }
}

output aiSearchResourceId string = aiSearch.id
output aiSearchResourceName string = aiSearch.name

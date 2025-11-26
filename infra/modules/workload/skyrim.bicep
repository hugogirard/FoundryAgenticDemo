param location string
param cosmosDBResourceName string
param storageResourceName string

var tags = {
  SecurityControl: 'Ignore'
  Workload: 'Skyrim Crimes'
}

resource cosmosDB 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' = {
  name: cosmosDBResourceName
  location: location
  kind: 'GlobalDocumentDB'
  tags: tags
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    disableLocalAuth: false
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    publicNetworkAccess: 'Enabled'
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

resource db 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2025-11-01-preview' = {
  parent: cosmosDB
  name: 'skyrim'
  properties: {
    resource: {
      id: 'skyrim'
    }
    options: {
      autoscaleSettings: {
        maxThroughput: 4000
      }
    }
  }
}

// resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2025-11-01-preview' = {
//   parent: db
//   name: 'crime'
//   properties: {
//     resource: {
//       id: 'crime'
//       partitionKey: {
//         paths: [
//           '/city'
//         ]
//         kind: 'Hash'
//       }
//       vectorEmbeddingPolicy: {
//         vectorEmbeddings: [
//           {
//             dataType: 'float32'
//             dimensions: 1536
//             distanceFunction: 'cosine'
//             path: '/descriptionVector'
//           }
//         ]
//       }
//       fullTextPolicy: {
//         defaultLanguage: 'en-US'
//         fullTextPaths: [
//           {
//             language: 'en-US'
//             path: '/description'
//           }
//         ]
//       }
//       indexingPolicy: {
//         fullTextIndexes: [
//           {
//             path: '/description'
//           }
//         ]
//       }
//     }
//   }
// }

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageResourceName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  tags: tags
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
    }
    allowSharedKeyAccess: true
  }
}

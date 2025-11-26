param location string
param cosmosDBResourceName string
param storageResourceName string

var tags = {
  SecurityControl: 'Ignore'
  Workload: 'Skyrim Crimes'
}

// resource databaseAccounts_testcmsdb_name_resource 'Microsoft.DocumentDB/databaseAccounts@2025-05-01-preview' = {
//   name: 'bob'
//   location: 'West US 2'
//   tags: {
//     defaultExperience: 'Core (SQL)'
//     'hidden-workload-type': 'Development/Testing'
//     'hidden-cosmos-mmspecial': ''
//   }
//   kind: 'GlobalDocumentDB'
//   identity: {
//     type: 'None'
//   }
//   properties: {
//     publicNetworkAccess: 'Enabled'
//     enableAutomaticFailover: true
//     enableMultipleWriteLocations: false
//     isVirtualNetworkFilterEnabled: false
//     virtualNetworkRules: []
//     disableKeyBasedMetadataWriteAccess: false
//     enableFreeTier: false
//     enableAnalyticalStorage: false
//     analyticalStorageConfiguration: {
//       schemaType: 'WellDefined'
//     }
//     databaseAccountOfferType: 'Standard'
//     enableMaterializedViews: false
//     capacityMode: 'Provisioned'
//     defaultIdentity: 'FirstPartyIdentity'
//     networkAclBypass: 'None'
//     disableLocalAuth: true
//     enablePartitionMerge: false
//     enablePerRegionPerPartitionAutoscale: true
//     enableBurstCapacity: false
//     enablePriorityBasedExecution: false
//     defaultPriorityLevel: 'High'
//     minimalTlsVersion: 'Tls12'
//     consistencyPolicy: {
//       defaultConsistencyLevel: 'Session'
//       maxIntervalInSeconds: 5
//       maxStalenessPrefix: 100
//     }
//     locations: [
//       {
//         locationName: 'West US 2'
//         failoverPriority: 0
//         isZoneRedundant: false
//       }
//     ]
//     cors: []
//     capabilities: [
//       {
//         name: 'EnableNoSQLVectorSearch'
//       }
//     ]
//     ipRules: []
//     backupPolicy: {
//       type: 'Periodic'
//       periodicModeProperties: {
//         backupIntervalInMinutes: 240
//         backupRetentionIntervalInHours: 8
//         backupStorageRedundancy: 'Geo'
//       }
//     }
//     networkAclBypassResourceIds: []
//     diagnosticLogSettings: {
//       enableFullTextQuery: 'None'
//     }
//     capacity: {
//       totalThroughputLimit: 1000
//     }
//   }
// }

resource cosmosDB 'Microsoft.DocumentDB/databaseAccounts@2025-05-01-preview' = {
  name: cosmosDBResourceName
  location: location
  kind: 'GlobalDocumentDB'
  tags: tags
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    capabilities: [
      {
        name: 'EnableNoSQLVectorSearch'
      }
    ]
    disableLocalAuth: false
    enableAutomaticFailover: true
    enableMultipleWriteLocations: false
    publicNetworkAccess: 'Enabled'
    enableFreeTier: false
    enableAnalyticalStorage: false
    backupPolicy: {
      type: 'Periodic'
      periodicModeProperties: {
        backupIntervalInMinutes: 240
        backupRetentionIntervalInHours: 8
        backupStorageRedundancy: 'Geo'
      }
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
    capacity: {
      totalThroughputLimit: 1000
    }
  }
}

resource db 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2025-11-01-preview' = {
  parent: cosmosDB
  name: 'skyrim'
  properties: {
    resource: {
      id: 'skyrim'
    }
    // options: {
    //   autoscaleSettings: {
    //     maxThroughput: 4000
    //   }
    // }
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2025-11-01-preview' = {
  parent: db
  name: 'crime'
  properties: {
    resource: {
      id: 'crime'
      partitionKey: {
        paths: [
          '/city'
        ]
        kind: 'Hash'
      }
      // vectorEmbeddingPolicy: {
      //   vectorEmbeddings: [
      //     {
      //       dataType: 'float32'
      //       dimensions: 1536
      //       distanceFunction: 'cosine'
      //       path: '/descriptionVector'
      //     }
      //   ]
      // }
      fullTextPolicy: {
        defaultLanguage: 'en-US'
        fullTextPaths: [
          {
            language: 'en-US'
            path: '/description'
          }
        ]
      }
      indexingPolicy: {
        fullTextIndexes: [
          {
            path: '/description'
          }
        ]
      }
    }
  }
}

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

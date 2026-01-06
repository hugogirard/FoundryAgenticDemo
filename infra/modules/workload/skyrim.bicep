param location string
param cosmosDBResourceName string
param storageResourceName string
param appServicePlanName string
param storageFunctionResourceName string
param functionResourceName string
param logAnalyticResourceName string
param applicationInsightResourceName string
param containerResourceName string
param appServicePlanResourceName string
param webAppResourceName string
param appServiceLocation string

var tags = {
  SecurityControl: 'Ignore'
  Workload: 'Skyrim Crimes'
}

resource cosmosDB 'Microsoft.DocumentDB/databaseAccounts@2025-05-01-preview' = {
  name: cosmosDBResourceName
  location: location
  tags: {
    defaultExperience: 'Core (SQL)'
    'hidden-workload-type': 'Development/Testing'
    'hidden-cosmos-mmspecial': ''
    SecurityControl: 'Ignore'
    Workload: 'Skyrim Crimes'
  }
  kind: 'GlobalDocumentDB'
  properties: {
    publicNetworkAccess: 'Enabled'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    isVirtualNetworkFilterEnabled: false
    virtualNetworkRules: []
    disableKeyBasedMetadataWriteAccess: false
    enableFreeTier: false
    enableAnalyticalStorage: false
    analyticalStorageConfiguration: {
      schemaType: 'WellDefined'
    }
    databaseAccountOfferType: 'Standard'
    enableMaterializedViews: false
    capacityMode: 'Provisioned'
    defaultIdentity: 'FirstPartyIdentity'
    networkAclBypass: 'None'
    disableLocalAuth: false
    enablePartitionMerge: false
    enablePerRegionPerPartitionAutoscale: true
    enableBurstCapacity: false
    enablePriorityBasedExecution: false
    //defaultPriorityLevel: 'High'
    minimalTlsVersion: 'Tls12'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
      maxIntervalInSeconds: 5
      maxStalenessPrefix: 100
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    cors: []
    capabilities: [
      {
        name: 'EnableNoSQLVectorSearch'
      }
    ]
    ipRules: []
    backupPolicy: {
      type: 'Periodic'
      periodicModeProperties: {
        backupIntervalInMinutes: 240
        backupRetentionIntervalInHours: 8
        backupStorageRedundancy: 'Geo'
      }
    }
    networkAclBypassResourceIds: []
    diagnosticLogSettings: {
      enableFullTextQuery: 'None'
    }
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
          '/crimeType'
        ]
        kind: 'Hash'
      }
      vectorEmbeddingPolicy: {
        vectorEmbeddings: [
          {
            dataType: 'float32'
            dimensions: 1536
            distanceFunction: 'cosine'
            path: '/descriptionVector'
          }
        ]
      }
      fullTextPolicy: {
        defaultLanguage: 'en-US'
        fullTextPaths: [
          {
            language: 'en-US'
            path: '/crimeName'
          }
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
          {
            path: '/crimeName'
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

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2025-06-01' = {
  parent: storage
  name: 'default'
}

resource bountyContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-06-01' = {
  parent: blobService
  name: 'bounty'
  properties: {
    publicAccess: 'None'
  }
}

resource crimePenaltyContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-06-01' = {
  parent: blobService
  name: 'crimepenalty'
  properties: {
    publicAccess: 'None'
  }
}

module function '../serverless/function.bicep' = {
  name: 'function'
  params: {
    location: location
    appServicePlanName: appServicePlanName
    storageName: storageFunctionResourceName
    functionResourceName: functionResourceName
    cosmosDBResourceName: cosmosDB.name
    logAnalyticResourceName: logAnalyticResourceName
    applicationInsightResourceName: applicationInsightResourceName
    tags: tags
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2025-11-01' = {
  name: containerResourceName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
    publicNetworkAccess: 'Enabled'
  }
}

resource asp 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: appServicePlanResourceName
  location: appServiceLocation
  kind: 'linux'
  properties: {
    reserved: true
  }
  sku: {
    tier: 'PremiumV3'
    name: 'P1V3'
  }
}

resource web 'Microsoft.Web/sites@2024-11-01' = {
  name: webAppResourceName
  location: appServiceLocation
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    siteConfig: {
      appSettings: []
      linuxFxVersion: 'sitecontainers'
      acrUseManagedIdentityCreds: true
      alwaysOn: true
    }
    serverFarmId: asp.id
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
    autoGeneratedDomainNameLabelScope: 'TenantReuse'
  }
}

resource appSettings 'Microsoft.Web/sites/config@2024-11-01' = {
  name: 'appsettings'
  parent: web
  properties: {
    SERVER_URL: 'https://${web.properties.defaultHostName}'
  }
}

@description('Built-in Role: [AcrPull]')
resource acr_pull 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
  scope: subscription()
}

module webArcPull 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = {
  name: 'webArcPull'
  params: {
    principalId: web.identity.principalId
    resourceId: acr.id
    roleDefinitionId: acr_pull.id
  }
}

output functionCrimeResourceName string = function.outputs.functionResourceName
output webApiResourceName string = web.name
output acrResourceName string = acr.name

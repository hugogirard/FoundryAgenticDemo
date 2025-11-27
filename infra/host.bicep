targetScope = 'resourceGroup'

@minLength(1)
@description('Primary location for all resources')
@allowed(['canadaeast', 'westus'])
param location string

@description('The name of the resource group that will contains the resource')
param resourceGroupName string

@description('The name of the Azure AI Foundry project workspace ID')
param projectWorkspaceId string

@description('The Azure AI Foundry Resource Name')
param foundryResourceName string

@description('The Azure AI Seach Resource Name')
param aiSearchConnectionResourceName string

@description('The Azure storage resource name')
param azureStorageConnectionResourceName string

@description('The Azure storage resource name')
param cosmosDBConnectionResourceName string

@description('The Azure project cap host name')
param projectCapHostName string

@description('The Azure project name in Azure AI Foundry')
param projectNameResourceName string

@description('The Azure project name in Azure AI Foundry')
param azureStorageResourceName string

@description('The Azure project name in Azure AI Foundry')
param cosmosDBNameResourceName string

resource foundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' existing = {
  name: projectNameResourceName
}

#disable-next-line no-unused-vars
var resourceToken = toLower(uniqueString(subscription().id, resourceGroupName, location))

module formatProjectWorkspaceId 'modules/ai/format-project-workspace-id.bicep' = {
  name: 'format-project-workspace-id-${resourceToken}-deployment'
  params: {
    #disable-next-line BCP318
    projectWorkspaceId: projectWorkspaceId
  }
}

// // Add capability host
module projectCapabilityHost 'modules/ai/add-project-capability-host.bicep' = {
  params: {
    accountName: foundryResourceName
    aiSearchConnection: aiSearchConnectionResourceName
    azureStorageConnection: azureStorageConnectionResourceName
    cosmosDBConnection: cosmosDBConnectionResourceName
    projectCapHost: projectCapHostName
    projectName: projectNameResourceName
  }
}

// The Storage Blob Data Owner role must be assigned after the caphost is created
module rbacProjectStoragePostDeploy 'modules/ai/rbac/blob-storage-container-role-assignments.bicep' = {
  params: {
    aiProjectPrincipalId: foundryProject.identity.principalId
    storageName: azureStorageResourceName
    workspaceId: formatProjectWorkspaceId.outputs.projectWorkspaceIdGuid
  }
  dependsOn: [
    projectCapabilityHost
  ]
}

// // The Cosmos Built-In Data Contributor role must be assigned after the caphost is created
module rbacCosmosDBPostDeploy 'modules/ai/rbac/cosmos-container-role-assignments.bicep' = {
  params: {
    cosmosAccountName: cosmosDBNameResourceName
    projectPrincipalId: foundryProject.identity.principalId
    projectWorkspaceId: formatProjectWorkspaceId.outputs.projectWorkspaceIdGuid
  }
  dependsOn: [
    projectCapabilityHost
  ]
}

targetScope = 'subscription'

@minLength(1)
@description('Primary location for all resources')
@allowed(['canadaeast', 'westus'])
param location string

@description('The name of the resource group that will contains the resource')
param resourceGroupName string

@description('The chat completion model deployment name')
param chatCompleteionDeploymentName string

@description('The chat completion model deployment SKU')
@allowed(['GlobalStandard'])
param chatDeploymentSku string

@description('The chat completion model properties')
param chatModelProperties object

@description('The chat completion model SKU capacity')
param chatModelSkuCapacity int

@description('The embedding model deployment name')
param embeddingDeploymentName string

@description('The embedding model deployment SKU')
@allowed(['GlobalStandard'])
param embeddingDeploymentSku string

@description('The embedding model properties')
param embeddingModelProperties object

@description('The embedding model SKU capacity')
param embeddingModelSkuCapacity int

@description('Use Azure Managed Resources for Foundry')
param useAzureManagedResources bool

var abbrs = loadJsonContent('./abbreviations.json')

// Generate a unique token to be used in naming resources.
// Remove linter suppression after using.
#disable-next-line no-unused-vars
var resourceToken = toLower(uniqueString(subscription().id, resourceGroupName, location))

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module vnet 'modules/network/vnet.bicep' = {
  scope: rg
  params: {
    location: location
  }
}

module foundryDependencies 'modules/ai/foundry.dependencies.bicep' = if (!useAzureManagedResources) {
  scope: rg
  params: {
    location: location
    aiSearchName: '${abbrs.searchSearchServices}${resourceToken}'
    azureStorageName: 'strf${replace(resourceToken,'-','')}'
    cosmosDBName: '${abbrs.documentDBDatabaseAccounts}${resourceToken}'
  }
}

module foundry 'modules/ai/foundry.account.bicep' = {
  scope: rg
  params: {
    location: location
    accountName: 'foundry-${resourceToken}'
    agentSubnetId: vnet.outputs.agentSubnetId
  }
}

module chatCompletionModel 'modules/ai/model-deployment.bicep' = {
  scope: rg
  params: {
    aiFoundryAccountName: foundry.outputs.accountName
    deploymentName: chatCompleteionDeploymentName
    deploymentSku: chatDeploymentSku
    modelProperties: chatModelProperties
    skuCapacity: chatModelSkuCapacity
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
  }
  dependsOn: [
    foundryProjectBYOResources
  ]
}

module embeddingnModel 'modules/ai/model-deployment.bicep' = {
  scope: rg
  params: {
    aiFoundryAccountName: foundry.outputs.accountName
    deploymentName: embeddingDeploymentName
    deploymentSku: embeddingDeploymentSku
    modelProperties: embeddingModelProperties
    skuCapacity: embeddingModelSkuCapacity
    versionUpgradeOption: 'NoAutoUpgrade'
  }
  dependsOn: [
    foundryProjectBYOResources
    chatCompletionModel
  ]
}

// DNS And Private Endpoint
module dnsPrivateEndpoint 'modules/network/private-endpoint-dns.bicep' = if (!useAzureManagedResources) {
  scope: rg
  params: {
    #disable-next-line BCP318
    aiAccountName: foundry.outputs.accountName
    #disable-next-line BCP318
    aiSearchName: foundryDependencies.outputs.aiSearchName
    #disable-next-line BCP318
    cosmosDBName: foundryDependencies.outputs.cosmosDBName
    peSubnetName: vnet.outputs.peSubnetName
    #disable-next-line BCP318
    storageName: foundryDependencies.outputs.azureStorageName
    suffix: resourceToken
    vnetName: vnet.outputs.virtualNetworkName
  }
}

// Now we create the AI Project
module foundryProjectBYOResources 'modules/ai/project_byo_resources.bicep' = if (!useAzureManagedResources) {
  scope: rg
  params: {
    location: location
    #disable-next-line BCP318
    accountName: foundry.outputs.accountName
    #disable-next-line BCP318
    aiSearchName: foundryDependencies.outputs.aiSearchName
    #disable-next-line BCP318
    azureStorageName: foundryDependencies.outputs.azureStorageName
    #disable-next-line BCP318
    cosmosDBName: foundryDependencies.outputs.cosmosDBName
    displayName: 'skyrim'
    projectDescription: 'crime tracking in Skyrim'
    projectName: 'skyrim'
  }
}

module foundryProjectManagedResources 'modules/ai/project_managed_resources.bicep' = {
  scope: rg
  params: {
    location: location
    accountName: foundry.outputs.accountName
    displayName: 'skyrim'
    projectDescription: 'crime tracking in Skyrim'
    projectName: 'skyrim'
  }
}

/*
  Assigns the project SMI the storage blob data contributor role on the storage account
  for the AI Project
*/
module storageProjectRBAC 'modules/ai/rbac/azure-storage-account-role-assignment.bicep' = if (!useAzureManagedResources) {
  scope: rg
  params: {
    #disable-next-line BCP318
    azureStorageName: foundryDependencies.outputs.azureStorageName
    #disable-next-line BCP318
    projectPrincipalId: foundryProjectBYOResources.outputs.projectPrincipalId
  }
  dependsOn: [
    dnsPrivateEndpoint
  ]
}

// The Comos DB Operator role must be assigned before the caphost is created
module cosmosDBProjectRBAC 'modules/ai/rbac/cosmosdb-account-role-assignment.bicep' = if (!useAzureManagedResources) {
  scope: rg
  params: {
    #disable-next-line BCP318
    cosmosDBName: foundryDependencies.outputs.cosmosDBName
    #disable-next-line BCP318
    projectPrincipalId: foundryProjectBYOResources.outputs.projectPrincipalId
  }
}

// This role can be assigned before or after the caphost is created
module searchProjectRBAC 'modules/ai/rbac/ai-search-role-assignments.bicep' = if (!useAzureManagedResources) {
  scope: rg
  params: {
    #disable-next-line BCP318
    aiSearchName: foundryDependencies.outputs.aiSearchName
    #disable-next-line BCP318
    projectPrincipalId: foundryProjectBYOResources.outputs.projectPrincipalId
  }
}

output azureFoundryResourceName string = foundry.outputs.accountName
output azureFoundryResourceId string = foundry.outputs.accountID

output azureFoundryProjectResourceName string = useAzureManagedResources
  ? foundryProjectManagedResources.outputs.projectName
  : foundryProjectBYOResources.outputs.projectName
output azureFoundryProjectResourceId string = useAzureManagedResources
  ? foundryProjectManagedResources.outputs.projectId
  : foundryProjectBYOResources.outputs.projectId

output foundryProjectProjectPrincipalId string = useAzureManagedResources
  ? foundryProjectManagedResources.outputs.projectPrincipalId
  : foundryProjectBYOResources.outputs.projectPrincipalId

output aiSearchConnection string = useAzureManagedResources ? '' : foundryProjectBYOResources.outputs.aiSearchConnection
output azureStorageConnection string = useAzureManagedResources
  ? ''
  : foundryProjectBYOResources.outputs.azureStorageConnection
output cosmosDBConnection string = useAzureManagedResources ? '' : foundryProjectBYOResources.outputs.cosmosDBConnection
output projectWorkspaceId string = useAzureManagedResources
  ? foundryProjectManagedResources.outputs.projectWorkspaceId
  : foundryProjectBYOResources.outputs.projectWorkspaceId
output aiSearchResourceName string = useAzureManagedResources ? '' : foundryDependencies.outputs.aiSearchName
output azureStorageResourceName string = useAzureManagedResources ? '' : foundryDependencies.outputs.azureStorageName
output cosmosDBResourceName string = useAzureManagedResources ? '' : foundryDependencies.outputs.cosmosDBName
output resourceGroupName string = rg.name

targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
@allowed(['canadaeast', 'westus'])
param location string

@description('The name of the resource group that will contains the resource')
param resourceGroupName string

@description('The chat completion model deployment name')
param chatCompleteionDeploymentName string = 'gpt-4.1-mini'

@description('The chat completion model deployment SKU')
@allowed(['GlobalStandard'])
param chatDeploymentSku string = 'GlobalStandard'

@description('The chat completion model properties')
param chatModelProperties object = {
  format: 'OpenAI'
  name: 'gpt-4.1-mini'
  version: '2025-04-14'
}

@description('The chat completion model SKU capacity')
param chatModelSkuCapacity int = 2375

@description('The embedding model deployment name')
param embeddingDeploymentName string = 'text-embedding-3-large'

@description('The embedding model deployment SKU')
@allowed(['GlobalStandard'])
param embeddingDeploymentSku string = 'GlobalStandard'

@description('The embedding model properties')
param embeddingModelProperties object = {
  format: 'OpenAI'
  name: 'text-embedding-3-large'
  version: '1'
}

@description('The embedding model SKU capacity')
param embeddingModelSkuCapacity int = 150

// @description('The chat completion model you want to use')
// param chatCompletionModel string

var abbrs = loadJsonContent('./abbreviations.json')

// Generate a unique token to be used in naming resources.
// Remove linter suppression after using.
#disable-next-line no-unused-vars
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Temp switch since sometimes if you deploy foundry more than once
// the capability host crash
var deployFoundry = true

// Use Azure Managed resource for AI Foundry
var useAzureManagedResource = true

// Deploy the model in the deployment
var deployModel = false

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

module foundryDependencies 'modules/ai/foundry.dependencies.bicep' = if (deployFoundry && !useAzureManagedResource) {
  scope: rg
  params: {
    location: location
    aiSearchName: '${abbrs.searchSearchServices}${resourceToken}'
    azureStorageName: 'strf${replace(resourceToken,'-','')}'
    cosmosDBName: '${abbrs.documentDBDatabaseAccounts}${resourceToken}'
  }
}

module foundry 'modules/ai/foundry.account.bicep' = if (deployFoundry) {
  scope: rg
  params: {
    location: location
    accountName: 'foundry-${resourceToken}'
    agentSubnetId: vnet.outputs.agentSubnetId
  }
}

module chatCompletionModel 'modules/ai/model-deployment.bicep' = if (deployModel) {
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
    foundryProject
  ]
}

module embeddingnModel 'modules/ai/model-deployment.bicep' = if (deployModel) {
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
    foundryProject
  ]
}

// DNS And Private Endpoint
module dnsPrivateEndpoint 'modules/network/private-endpoint-dns.bicep' = if (deployFoundry && !useAzureManagedResource) {
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
module foundryProject 'modules/ai/project.bicep' = if (deployFoundry) {
  scope: rg
  params: {
    location: location
    #disable-next-line BCP318
    accountName: foundry.outputs.accountName
    #disable-next-line BCP318
    aiSearchName: !useAzureManagedResource ? foundryDependencies.outputs.aiSearchName : ''
    #disable-next-line BCP318
    azureStorageName: !useAzureManagedResource ? foundryDependencies.outputs.azureStorageName : ''
    #disable-next-line BCP318
    cosmosDBName: !useAzureManagedResource ? foundryDependencies.outputs.cosmosDBName : ''
    displayName: 'skyrim'
    projectDescription: 'crime tracking in Skyrim'
    projectName: 'skyrim'
    useAzureManagedResource: useAzureManagedResource
  }
}

module formatProjectWorkspaceId 'modules/ai/format-project-workspace-id.bicep' = if (deployFoundry && !useAzureManagedResource) {
  scope: rg
  name: 'format-project-workspace-id-${resourceToken}-deployment'
  params: {
    #disable-next-line BCP318
    projectWorkspaceId: foundryProject.outputs.projectWorkspaceId
  }
}

/*
  Assigns the project SMI the storage blob data contributor role on the storage account
  for the AI Project
*/
module storageProjectRBAC 'modules/ai/rbac/azure-storage-account-role-assignment.bicep' = if (deployFoundry && !useAzureManagedResource) {
  scope: rg
  params: {
    #disable-next-line BCP318
    azureStorageName: foundryDependencies.outputs.azureStorageName
    #disable-next-line BCP318
    projectPrincipalId: foundryProject.outputs.projectPrincipalId
  }
  dependsOn: [
    dnsPrivateEndpoint
  ]
}

// The Comos DB Operator role must be assigned before the caphost is created
module cosmosDBProjectRBAC 'modules/ai/rbac/cosmosdb-account-role-assignment.bicep' = if (deployFoundry && !useAzureManagedResource) {
  scope: rg
  params: {
    #disable-next-line BCP318
    cosmosDBName: foundryDependencies.outputs.cosmosDBName
    #disable-next-line BCP318
    projectPrincipalId: foundryProject.outputs.projectPrincipalId
  }
}

// This role can be assigned before or after the caphost is created
module searchProjectRBAC 'modules/ai/rbac/ai-search-role-assignments.bicep' = if (deployFoundry && !useAzureManagedResource) {
  scope: rg
  params: {
    #disable-next-line BCP318
    aiSearchName: foundryDependencies.outputs.aiSearchName
    #disable-next-line BCP318
    projectPrincipalId: foundryProject.outputs.projectPrincipalId
  }
}

var projectCapHost string = 'capskyrim'

// Add capability host
module projectCapabilityHost 'modules/ai/add-project-capability-host.bicep' = if (deployFoundry && !useAzureManagedResource) {
  scope: rg
  params: {
    #disable-next-line BCP318
    accountName: foundry.outputs.accountName
    #disable-next-line BCP318
    aiSearchConnection: foundryProject.outputs.aiSearchConnection
    #disable-next-line BCP318
    azureStorageConnection: foundryProject.outputs.azureStorageConnection
    #disable-next-line BCP318
    cosmosDBConnection: foundryProject.outputs.cosmosDBConnection
    projectCapHost: projectCapHost
    #disable-next-line BCP318
    projectName: foundryProject.outputs.projectName
  }
}

// The Storage Blob Data Owner role must be assigned after the caphost is created
module rbacProjectStoragePostDeploy 'modules/ai/rbac/blob-storage-container-role-assignments.bicep' = if (deployFoundry && !useAzureManagedResource) {
  scope: rg
  params: {
    #disable-next-line BCP318
    aiProjectPrincipalId: foundryProject.outputs.projectPrincipalId
    #disable-next-line BCP318
    storageName: foundryDependencies.outputs.azureStorageName
    #disable-next-line BCP318
    workspaceId: formatProjectWorkspaceId.outputs.projectWorkspaceIdGuid
  }
  dependsOn: [
    projectCapabilityHost
  ]
}

// The Cosmos Built-In Data Contributor role must be assigned after the caphost is created
module rbacCosmosDBPostDeploy 'modules/ai/rbac/cosmos-container-role-assignments.bicep' = if (deployFoundry && !useAzureManagedResource) {
  scope: rg
  params: {
    #disable-next-line BCP318
    cosmosAccountName: foundryDependencies.outputs.cosmosDBName
    #disable-next-line BCP318
    projectPrincipalId: foundryProject.outputs.projectPrincipalId
    #disable-next-line BCP318
    projectWorkspaceId: formatProjectWorkspaceId.outputs.projectWorkspaceIdGuid
  }
  dependsOn: [
    projectCapabilityHost
  ]
}

/*  Workload Specific and Agents */

/* Separate AI Search Instance for Foundry IQ */
module foundryIQSearch 'modules/ai/IQ/search.bicep' = {
  scope: rg
  params: {
    location: location
    aiSearchName: '${abbrs.searchSearchServices}foundryiq-${resourceToken}'
  }
}

/* Create all resources for the agents needed for Skyrim crimes */
module skyrimWorkload 'modules/workload/skyrim.bicep' = {
  scope: rg
  params: {
    location: location
    cosmosDBResourceName: '${abbrs.documentDBDatabaseAccounts}elder-${resourceToken}'
    storageResourceName: 'strk${replace(resourceToken,'-','')}'
    appServicePlanName: '${abbrs.webServerFarms}func-${resourceToken}'
    storageFunctionResourceName: 'strf${replace(resourceToken,'-','')}'
    functionResourceName: '${abbrs.webSitesFunctions}crime'
  }
}

output functionCrimeResourceName string = skyrimWorkload.outputs.functionCrimeResourceName

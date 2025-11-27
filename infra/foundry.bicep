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

module foundryDependencies 'modules/ai/foundry.dependencies.bicep' = {
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
    foundryProject
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
    foundryProject
    chatCompletionModel
  ]
}

// DNS And Private Endpoint
module dnsPrivateEndpoint 'modules/network/private-endpoint-dns.bicep' = {
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
module foundryProject 'modules/ai/project.bicep' = {
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

// module formatProjectWorkspaceId 'modules/ai/format-project-workspace-id.bicep' = if (deployFoundry && !useAzureManagedResource) {
//   scope: rg
//   name: 'format-project-workspace-id-${resourceToken}-deployment'
//   params: {
//     #disable-next-line BCP318
//     projectWorkspaceId: foundryProject.outputs.projectWorkspaceId
//   }
// }

/*
  Assigns the project SMI the storage blob data contributor role on the storage account
  for the AI Project
*/
module storageProjectRBAC 'modules/ai/rbac/azure-storage-account-role-assignment.bicep' = {
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
module cosmosDBProjectRBAC 'modules/ai/rbac/cosmosdb-account-role-assignment.bicep' = {
  scope: rg
  params: {
    #disable-next-line BCP318
    cosmosDBName: foundryDependencies.outputs.cosmosDBName
    #disable-next-line BCP318
    projectPrincipalId: foundryProject.outputs.projectPrincipalId
  }
}

// This role can be assigned before or after the caphost is created
module searchProjectRBAC 'modules/ai/rbac/ai-search-role-assignments.bicep' = {
  scope: rg
  params: {
    #disable-next-line BCP318
    aiSearchName: foundryDependencies.outputs.aiSearchName
    #disable-next-line BCP318
    projectPrincipalId: foundryProject.outputs.projectPrincipalId
  }
}

// var projectCapHost string = 'capskyrim'

// // Add capability host
// module projectCapabilityHost 'modules/ai/add-project-capability-host.bicep' = if (deployFoundry && !useAzureManagedResource) {
//   scope: rg
//   params: {
//     #disable-next-line BCP318
//     accountName: foundry.outputs.accountName
//     #disable-next-line BCP318
//     aiSearchConnection: foundryProject.outputs.aiSearchConnection
//     #disable-next-line BCP318
//     azureStorageConnection: foundryProject.outputs.azureStorageConnection
//     #disable-next-line BCP318
//     cosmosDBConnection: foundryProject.outputs.cosmosDBConnection
//     projectCapHost: projectCapHost
//     #disable-next-line BCP318
//     projectName: foundryProject.outputs.projectName
//   }
// }

// The Storage Blob Data Owner role must be assigned after the caphost is created
// module rbacProjectStoragePostDeploy 'modules/ai/rbac/blob-storage-container-role-assignments.bicep' = if (deployFoundry && !useAzureManagedResource) {
//   scope: rg
//   params: {
//     #disable-next-line BCP318
//     aiProjectPrincipalId: foundryProject.outputs.projectPrincipalId
//     #disable-next-line BCP318
//     storageName: foundryDependencies.outputs.azureStorageName
//     #disable-next-line BCP318
//     workspaceId: formatProjectWorkspaceId.outputs.projectWorkspaceIdGuid
//   }
//   dependsOn: [
//     projectCapabilityHost
//   ]
// }

// // The Cosmos Built-In Data Contributor role must be assigned after the caphost is created
// module rbacCosmosDBPostDeploy 'modules/ai/rbac/cosmos-container-role-assignments.bicep' = if (deployFoundry && !useAzureManagedResource) {
//   scope: rg
//   params: {
//     #disable-next-line BCP318
//     cosmosAccountName: foundryDependencies.outputs.cosmosDBName
//     #disable-next-line BCP318
//     projectPrincipalId: foundryProject.outputs.projectPrincipalId
//     #disable-next-line BCP318
//     projectWorkspaceId: formatProjectWorkspaceId.outputs.projectWorkspaceIdGuid
//   }
//   dependsOn: [
//     projectCapabilityHost
//   ]
// }

/*  Workload Specific and Agents */

/* Separate AI Search Instance for Foundry IQ */
// module foundryIQSearch 'modules/ai/IQ/search.bicep' = {
//   scope: rg
//   params: {
//     location: location
//     aiSearchName: '${abbrs.searchSearchServices}foundryiq-${resourceToken}'
//   }
// }

/* Create all resources for the agents needed for Skyrim crimes */
// module skyrimWorkload 'modules/workload/skyrim.bicep' = {
//   scope: rg
//   params: {
//     location: location
//     cosmosDBResourceName: '${abbrs.documentDBDatabaseAccounts}elder-${resourceToken}'
//     storageResourceName: 'strk${replace(resourceToken,'-','')}'
//     appServicePlanName: '${abbrs.webServerFarms}func-${resourceToken}'
//     storageFunctionResourceName: 'strf${replace(resourceToken,'-','')}'
//     functionResourceName: '${abbrs.webSitesFunctions}crime'
//   }
// }

// output functionCrimeResourceName string = skyrimWorkload.outputs.functionCrimeResourceName

output azureFoundryResourceName string = foundry.outputs.accountName
output azureFoundryResourceId string = foundry.outputs.accountID
output azureFoundryProjectResourceName string = foundryProject.outputs.projectName
output azureFoundryProjectResourceId string = foundryProject.outputs.projectId
output aiSearchConnection string = foundryProject.outputs.aiSearchConnection
output azureStorageConnection string = foundryProject.outputs.azureStorageConnection
output cosmosDBConnection string = foundryProject.outputs.cosmosDBConnection

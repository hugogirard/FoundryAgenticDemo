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

var abbrs = loadJsonContent('./abbreviations.json')

// Generate a unique token to be used in naming resources.
// Remove linter suppression after using.
#disable-next-line no-unused-vars
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

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

// DNS And Private Endpoint
module dnsPrivateEndpoint 'modules/network/private-endpoint-dns.bicep' = {
  scope: rg
  params: {
    aiAccountName: foundry.outputs.accountName
    aiSearchName: foundryDependencies.outputs.aiSearchName
    cosmosDBName: foundryDependencies.outputs.cosmosDBName
    peSubnetName: vnet.outputs.peSubnetName
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
    accountName: foundry.outputs.accountName
    aiSearchName: foundryDependencies.outputs.aiSearchName
    azureStorageName: foundryDependencies.outputs.azureStorageName
    cosmosDBName: foundryDependencies.outputs.cosmosDBName
    displayName: 'skyrim'
    projectDescription: 'crime tracking in Skyrim'
    projectName: 'skyrim'
  }
}

module formatProjectWorkspaceId 'modules/ai/format-project-workspace-id.bicep' = {
  scope: rg
  name: 'format-project-workspace-id-${resourceToken}-deployment'
  params: {
    projectWorkspaceId: foundryProject.outputs.projectWorkspaceId
  }
}

/*
  Assigns the project SMI the storage blob data contributor role on the storage account
  for the AI Project
*/
module storageProjectRBAC 'modules/ai/rbac/azure-storage-account-role-assignment.bicep' = {
  scope: rg
  params: {
    azureStorageName: foundryDependencies.outputs.azureStorageName
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
    cosmosDBName: foundryDependencies.outputs.cosmosDBName
    projectPrincipalId: foundryProject.outputs.projectPrincipalId
  }
}

// This role can be assigned before or after the caphost is created
module searchProjectRBAC 'modules/ai/rbac/ai-search-role-assignments.bicep' = {
  scope: rg
  params: {
    aiSearchName: foundryDependencies.outputs.aiSearchName
    projectPrincipalId: foundryProject.outputs.projectPrincipalId
  }
}

var projectCapHost string = 'caphostskyrim'

// Add capability host
module projectCapabilityHost 'modules/ai/add-project-capability-host.bicep' = {
  scope: rg
  params: {
    accountName: foundry.outputs.accountName
    aiSearchConnection: foundryProject.outputs.aiSearchConnection
    azureStorageConnection: foundryProject.outputs.azureStorageConnection
    cosmosDBConnection: foundryProject.outputs.cosmosDBConnection
    projectCapHost: projectCapHost
    projectName: foundryProject.outputs.projectName
  }
}

// The Storage Blob Data Owner role must be assigned after the caphost is created
module rbacProjectStoragePostDeploy 'modules/ai/rbac/blob-storage-container-role-assignments.bicep' = {
  scope: rg
  params: {
    aiProjectPrincipalId: foundryProject.outputs.projectPrincipalId
    storageName: foundryDependencies.outputs.azureStorageName
    workspaceId: formatProjectWorkspaceId.outputs.projectWorkspaceIdGuid
  }
}

// The Cosmos Built-In Data Contributor role must be assigned after the caphost is created
module rbacCosmosDBPostDeploy 'modules/ai/rbac/cosmos-container-role-assignments.bicep' = {
  scope: rg
  params: {
    cosmosAccountName: foundryDependencies.outputs.cosmosDBName
    projectPrincipalId: foundryProject.outputs.projectPrincipalId
    projectWorkspaceId: formatProjectWorkspaceId.outputs.projectWorkspaceIdGuid
  }
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
    cosmosDBResourceName: '${abbrs.documentDBDatabaseAccounts}skyrim-${resourceToken}'
    storageResourceName: 'strk${replace(resourceToken,'-','')}'
  }
}

targetScope = 'resourceGroup'

param location string
param resourceGroupName string
param foundryResourceName string

@description('If you want your app service located to another region')
param appServiceLocation string

var abbrs = loadJsonContent('./abbreviations.json')

resource foundry 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: foundryResourceName
  scope: resourceGroup()
}

#disable-next-line no-unused-vars
var resourceToken = toLower(uniqueString(subscription().id, resourceGroupName, location))

/* Separate AI Search Instance for Foundry IQ */
module foundryIQSearch 'modules/ai/IQ/search.bicep' = {
  params: {
    location: location
    aiSearchName: '${abbrs.searchSearchServices}foundryiq-${resourceToken}'
  }
}

/* Create all resources for the agents needed for Skyrim crimes */
module skyrimWorkload 'modules/workload/skyrim.bicep' = {
  params: {
    location: location
    cosmosDBResourceName: '${abbrs.documentDBDatabaseAccounts}elder-${resourceToken}'
    storageResourceName: 'strk${replace(resourceToken,'-','')}'
    appServicePlanName: '${abbrs.webServerFarms}func-${resourceToken}'
    storageFunctionResourceName: 'strf${replace(resourceToken,'-','')}'
    functionResourceName: '${abbrs.webSitesFunctions}crime-${resourceToken}'
    applicationInsightResourceName: '${abbrs.insightsComponents}${resourceToken}'
    logAnalyticResourceName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    containerResourceName: 'acr${replace(resourceToken,'-','')}'
    appServicePlanResourceName: '${abbrs.webServerFarms}${resourceToken}'
    webAppResourceName: '${abbrs.webSitesAppService}${resourceToken}'
    appServiceLocation: appServiceLocation
  }
}

module searchProjectRBAC 'modules/ai/rbac/ai-search-role-assignments.bicep' = {
  params: {
    #disable-next-line BCP318
    aiSearchName: foundryIQSearch.outputs.aiSearchResourceName
    #disable-next-line BCP318
    projectPrincipalId: foundry.identity.principalId
  }
}

output functionCrimeResourceName string = skyrimWorkload.outputs.functionCrimeResourceName
output webAppResourceName string = skyrimWorkload.outputs.webApiResourceName
output containerRegistryResourceName string = skyrimWorkload.outputs.acrResourceName

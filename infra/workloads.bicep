targetScope = 'resourceGroup'

@description('The location where all resources group will be create except the App Service')
param location string

@description('The name of the Foundry Resource to add RBAC permission')
param foundryResourceName string

@description('If you want your app service located to another region')
param appServiceLocation string

var abbrs = loadJsonContent('./abbreviations.json')

resource foundry 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: foundryResourceName
  scope: resourceGroup()
}

#disable-next-line no-unused-vars
var resourceToken = toLower(uniqueString(subscription().id, resourceGroup().name, location))

/* Separate AI Search Instance for Foundry IQ */
module foundryIQSearch 'modules/ai/IQ/search.bicep' = {
  name: 'foundryIQSearch'
  params: {
    location: location
    aiSearchName: '${abbrs.searchSearchServices}foundryiq-${resourceToken}'
  }
}

/* Create all resources for the agents needed for Skyrim crimes */
module skyrimWorkload 'modules/workload/skyrim.bicep' = {
  name: 'skyrimWorkload'
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
  name: 'searchProjectRBAC'
  params: {
    #disable-next-line BCP318
    aiSearchName: foundryIQSearch.outputs.aiSearchResourceName
    #disable-next-line BCP318
    projectPrincipalId: foundry.identity.principalId
  }
}

// output functionCrimeResourceName string = 'test'
// output webAppResourceName string = 'test'
// output containerRegistryResourceName string = 'test'

output functionCrimeResourceName string = skyrimWorkload.outputs.functionCrimeResourceName
output webAppResourceName string = skyrimWorkload.outputs.webApiResourceName
output containerRegistryResourceName string = skyrimWorkload.outputs.acrResourceName

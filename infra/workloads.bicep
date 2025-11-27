targetScope = 'resourceGroup'

param location string
param resourceGroupName string

var abbrs = loadJsonContent('./abbreviations.json')

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
  }
}

output functionCrimeResourceName string = skyrimWorkload.outputs.functionCrimeResourceName

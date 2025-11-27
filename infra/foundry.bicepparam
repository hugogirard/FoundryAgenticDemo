using 'foundry.bicep'

param chatCompleteionDeploymentName = 'gpt-4.1-mini'

param chatDeploymentSku = 'GlobalStandard'

param chatModelProperties = {
  format: 'OpenAI'
  name: 'gpt-4.1-mini'
  version: '2025-04-14'
}

param chatModelSkuCapacity = 2375

param embeddingDeploymentName = 'text-embedding-3-large'

param embeddingDeploymentSku = 'GlobalStandard'

param embeddingModelProperties = {
  format: 'OpenAI'
  name: 'text-embedding-3-large'
  version: '1'
}

param embeddingModelSkuCapacity = 150

param location = 'westus'

param resourceGroupName = 'rg-skyrim-world'

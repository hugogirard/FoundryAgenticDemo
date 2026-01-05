# Infrastructure Documentation

This document provides a comprehensive overview of the Azure infrastructure deployed for the Foundry Agentic Demo (Skyrim Crime Tracking System).

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Infrastructure Components](#infrastructure-components)
- [Deployment Process](#deployment-process)
- [Resource Configuration](#resource-configuration)
- [Network Architecture](#network-architecture)
- [GitHub Actions Workflows](#github-actions-workflows)

## Overview

The Foundry Agentic Demo infrastructure deploys a complete Azure AI-powered application stack that includes:

- **Azure AI Foundry** (Cognitive Services) for AI capabilities
- **Azure AI Search** for intelligent search and indexing
- **Azure Cosmos DB** for document storage with vector search capabilities
- **Azure Storage Accounts** for blob storage
- **Azure Functions** for serverless compute
- **Azure App Service** for container-based web applications
- **Azure Container Registry** for Docker image management
- **Virtual Network** with private endpoints for secure connectivity

The infrastructure supports two deployment modes:
1. **Azure Managed Resources** - Uses Azure-managed infrastructure for Foundry dependencies
2. **BYO (Bring Your Own) Resources** - Deploys custom AI Search, Storage, and Cosmos DB resources

## Architecture

The solution is organized into three main Bicep templates:

### 1. Foundry Infrastructure (`foundry.bicep`)
Deploys the core Azure AI Foundry environment with:
- AI Foundry Account (Cognitive Services)
- AI Project workspace ("skyrim")
- Model deployments (GPT-4.1-mini, text-embedding-3-large)
- Optional dependency resources (AI Search, Storage, Cosmos DB)
- Virtual network with subnets for agents and private endpoints
- RBAC role assignments for service identities

### 2. Host Infrastructure (`host.bicep`)
Configures the Foundry project with capability hosts:
- Formats project workspace IDs
- Adds capability hosts to the AI project
- Establishes connections to AI Search, Storage, and Cosmos DB
- Assigns post-deployment RBAC roles for blob storage and Cosmos DB containers

### 3. Workload Infrastructure (`workloads.bicep`)
Deploys application-specific resources:
- Cosmos DB for crime tracking data with vector search
- Azure Functions for MCP (Model Context Protocol) server
- Container Registry for Docker images
- App Service for the Mage Guild API
- Additional AI Search instance for Foundry IQ
- Supporting resources (Log Analytics, Application Insights)

## Infrastructure Components

### Azure AI Foundry

**Resource**: `Microsoft.CognitiveServices/accounts@2025-04-01-preview`

- **Name**: `foundry-{resourceToken}`
- **Location**: `westus` or `canadaeast`
- **SKU**: S0
- **Kind**: AIServices
- **Identity**: System Assigned Managed Identity
- **Features**:
  - Project management enabled
  - Custom subdomain
  - Network injection for agent subnet
  - Public network access enabled (for development)

**Model Deployments**:

1. **Chat Completion**: GPT-4.1-mini
   - Deployment SKU: GlobalStandard
   - Capacity: 2375 tokens
   - Version: 2025-04-14
   - Upgrade: OnceNewDefaultVersionAvailable

2. **Embeddings**: text-embedding-3-large
   - Deployment SKU: GlobalStandard
   - Capacity: 150 tokens
   - Version: 1
   - Upgrade: NoAutoUpgrade

### AI Project

**Name**: `skyrim`
- **Description**: "crime tracking in Skyrim"
- **Managed Identity**: System Assigned
- **Connections**:
  - AI Search connection (BYO mode)
  - Azure Storage connection (BYO mode)
  - Cosmos DB connection (BYO mode)

### Network Infrastructure

**Virtual Network**: `vnet-agent`
- **Address Space**: 192.168.0.0/16
- **Subnets**:
  1. **Agent Subnet** (`agent-subnet`): 192.168.0.0/24
     - Delegated to: Microsoft.App/environments
     - Purpose: AI agent network injection
  2. **Private Endpoint Subnet** (`pe-subnet`): 192.168.1.0/24
     - Purpose: Private endpoints for PaaS services

**Private Endpoints** (BYO mode only):
- AI Foundry Account
- AI Search
- Cosmos DB
- Azure Storage

### AI Search

**BYO Mode Resource**: `search-{resourceToken}`
- **SKU**: Standard
- **Location**: Same as resource group
- **Features**:
  - System Assigned Managed Identity
  - Public network access disabled
  - Private endpoint enabled
  - AAD authentication with API key fallback
  - Partition count: 1
  - Replica count: 1

**Foundry IQ Search**: `search-foundryiq-{resourceToken}`
- Separate AI Search instance for Foundry IQ capabilities
- Same configuration as BYO mode search

### Azure Storage

**Project Storage** (BYO mode): `strf{resourceToken}`
- **Kind**: StorageV2
- **SKU**: Standard_LRS
- **Features**:
  - Minimum TLS version: 1.2
  - Public blob access: Disabled
  - Public network access: Disabled
  - Shared key access: Disabled (AAD only)
  - Network ACLs: Deny default, bypass Azure Services

**Workload Storage**: `strk{resourceToken}`
- **Purpose**: Crime tracking data storage
- **Configuration**: Similar to project storage but with public network access enabled

**Function Storage**: `strf{resourceToken}`
- **Purpose**: Azure Functions backend storage
- **Container**: `app-package-crimeserver` for deployment packages

### Cosmos DB

**Project Database** (BYO mode): `cosmos-{resourceToken}`
- **Kind**: GlobalDocumentDB
- **Database**: `enterprise_memory`
- **Throughput**: Autoscale up to 6000 RU/s
- **Features**:
  - Local auth disabled (AAD only)
  - Public network access disabled
  - Private endpoint enabled
  - Consistency level: Session
  - Single region write

**Workload Database**: `cosmos-elder-{resourceToken}`
- **Database**: `skyrim`
- **Container**: `crime`
  - **Partition Key**: `/crimeType`
  - **Vector Embedding**:
    - Data type: float32
    - Dimensions: 1536
    - Distance function: cosine
    - Path: `/descriptionVector`
  - **Full-Text Search**:
    - Language: en-US
    - Paths: `/crimeName`, `/description`
  - **Indexing**: Full-text indexes on description and crimeName
- **Features**:
  - NoSQL Vector Search capability enabled
  - Total throughput limit: 1000 RU/s
  - Periodic backup (every 4 hours, 8-hour retention)
  - Geo-redundant backup storage

### Azure Functions

**Resource**: `func-crime-{resourceToken}`
- **Plan**: Flex Consumption (FC1)
- **Runtime**: .NET 8.0
- **Purpose**: MCP (Model Context Protocol) Crime Server
- **Configuration**:
  - Linux-based
  - Flex consumption tier
  - Application Insights integration
  - Cosmos DB connection for crime data
- **Environment Variables**:
  - `AzureWebJobsStorage`: Function storage connection string
  - `DEPLOYMENT_STORAGE_CONNECTION_STRING`: Deployment storage
  - `CosmosDB__ConnectionString`: Cosmos DB connection
  - `CosmosDB__DatabaseName`: skyrim
  - `CosmosDB__ContainerName`: crime

### Container Registry

**Resource**: `acr{resourceToken}`
- **SKU**: Standard
- **Location**: Same as workload resources
- **Features**:
  - Admin user enabled
  - Public network access enabled
  - RBAC: App Service managed identity has AcrPull role

### App Service

**App Service Plan**: `plan-{resourceToken}`
- **SKU**: Premium V3 (P1V3)
- **OS**: Linux
- **Location**: `eastus2` (configurable)

**Web App**: `app-{resourceToken}`
- **Purpose**: Mage Guild API
- **Kind**: Container app on Linux
- **Identity**: System Assigned Managed Identity
- **Configuration**:
  - HTTPS only
  - Always on: Enabled
  - ACR managed identity credentials: Enabled
  - Public network access: Enabled
  - Platform: Linux containers (sitecontainers)

### Monitoring

**Log Analytics Workspace**: `log-{resourceToken}`
- Centralized logging for all resources

**Application Insights**: `appi-{resourceToken}`
- Application performance monitoring
- Connected to Log Analytics workspace

## Deployment Process

### Prerequisites

1. Azure subscription with appropriate permissions
2. GitHub repository secrets configured:
   - `AZURE_CREDENTIALS`: Service principal credentials
   - `AZURE_SUBSCRIPTION`: Subscription ID
   - `PA_TOKEN`: Personal access token for GitHub secret management

### Deployment Stages

#### Stage 1: Foundry Infrastructure

**Workflow**: `.github/workflows/create-foundry-infra.yml`

**Trigger**: Manual (workflow_dispatch)

**Parameters**:
- `use-azure-managed-ressources` (boolean): Choose between Azure Managed or BYO resources mode

**Deployment**:
```bash
az deployment sub create \
  --location westus \
  --template-file ./infra/foundry.bicep \
  --parameters ./infra/foundry.bicepparam \
  --parameters useAzureManagedResources=true
```

**Outputs Stored as GitHub Secrets**:
- `RESOURCE_GROUP_NAME`
- `AZURE_FOUNDRY_RESOURCE_NAME`
- `AZURE_FOUNDRY_RESOURCE_ID`
- `AZURE_FOUNDRY_PROJECT_RESOURCE_NAME`
- `AZURE_FOUNDRY_PROJECT_RESOURCE_ID`
- `AI_SEARCH_CONNECTION`
- `AZURE_STORAGE_CONNECTION`
- `COSMOSDB_CONNECTION`
- `PROJECT_WORKSPACE_ID`
- `AI_SEARCH_RESOURCE_NAME`
- `AZURE_STORAGE_RESOURCENAME`
- `COSMOSDB_RESOURCE_NAME`
- `FOUNDRY_PROJECT_PROJECTPRINCIPALID`

**Resources Deployed**:
- Resource Group
- Virtual Network with subnets
- AI Foundry Account
- AI Project
- Model deployments
- (Conditional) AI Search, Storage, Cosmos DB
- (Conditional) Private endpoints and DNS zones
- RBAC role assignments

#### Stage 2: Workload Infrastructure

**Workflow**: `.github/workflows/create-workload-infra.yml`

**Trigger**: Manual (workflow_dispatch)

**Requires**: Completion of Stage 1

**Deployment**:
```bash
az deployment group create \
  --resource-group <RESOURCE_GROUP_NAME> \
  --template-file ./infra/workloads.bicep \
  --parameters location=westus \
  --parameters appServiceLocation=eastus2
```

**Outputs Stored as GitHub Secrets**:
- `FUNCTION_CRIMERE_SOURCENAME`
- `CONTAINER_REGISTRY_NAME`
- `MAGE_GUILD_WEB_API_RESOURCE_NAME`

**Resources Deployed**:
- Cosmos DB (crime database)
- Azure Storage (workload)
- Azure Functions (Crime MCP Server)
- Container Registry
- App Service Plan and Web App
- Log Analytics and Application Insights
- Foundry IQ Search instance
- RBAC role assignments

#### Stage 3: Deploy Crime Function

**Workflow**: `.github/workflows/deploy-crime-function.yml`

**Trigger**: Manual (workflow_dispatch)

**Process**:
1. Checkout repository
2. Setup .NET 8.0 SDK
3. Build .NET project
4. Deploy to Azure Functions

**Source**: `./src/MCP/crimeMCPServer/Crime`

#### Stage 4: Deploy Mage Guild API

**Workflow**: `.github/workflows/deploy-mage-guild-api.yml`

**Trigger**: Manual (workflow_dispatch)

**Process**:
1. Checkout repository
2. Login to Azure Container Registry
3. Build Docker image with ACR
4. Deploy container to App Service

**Source**: `./src/apis/mage-guild-api`

## Resource Configuration

### Parameter File (`foundry.bicepparam`)

```bicep
location = 'westus'
resourceGroupName = 'rg-skyrim-world'
useAzureManagedResources = true

chatCompleteionDeploymentName = 'gpt-4.1-mini'
chatDeploymentSku = 'GlobalStandard'
chatModelProperties = {
  format: 'OpenAI'
  name: 'gpt-4.1-mini'
  version: '2025-04-14'
}
chatModelSkuCapacity = 2375

embeddingDeploymentName = 'text-embedding-3-large'
embeddingDeploymentSku = 'GlobalStandard'
embeddingModelProperties = {
  format: 'OpenAI'
  name: 'text-embedding-3-large'
  version: '1'
}
embeddingModelSkuCapacity = 150
```

### Resource Naming Convention

The infrastructure uses Azure naming abbreviations from `abbreviations.json` combined with a unique resource token:

- Resource Token: `uniqueString(subscriptionId, resourceGroupName, location)`
- Format: `{abbreviation}-{purpose}-{resourceToken}` or `{abbreviation}{resourceToken}`

Examples:
- AI Search: `search-{resourceToken}` or `search-foundryiq-{resourceToken}`
- Storage: `strf{resourceToken}` (no hyphens due to naming restrictions)
- Cosmos DB: `cosmos-{resourceToken}` or `cosmos-elder-{resourceToken}`
- Function: `func-crime-{resourceToken}`
- App Service: `app-{resourceToken}`

## Network Architecture

### Security Boundaries

1. **Public Network Access**:
   - AI Foundry Account: Enabled (development)
   - Workload resources: Enabled
   - Function App: Enabled
   - App Service: Enabled

2. **Private Network Access** (BYO mode):
   - AI Search: Disabled public access, private endpoint only
   - Project Storage: Disabled public access, private endpoint only
   - Project Cosmos DB: Disabled public access, private endpoint only

### Network Flow

```
Internet
    ↓
[App Service / Function App]
    ↓
[AI Foundry Account] ←→ [Agent Subnet (192.168.0.0/24)]
    ↓
[Private Endpoints] ← [PE Subnet (192.168.1.0/24)]
    ↓
[AI Search / Storage / Cosmos DB]
```

### Subnet Delegation

- **Agent Subnet**: Delegated to `Microsoft.App/environments`
  - Enables Container Apps environment deployment
  - Used for AI agent network injection

## RBAC Configuration

### AI Project Permissions (BYO Mode)

**Storage Blob Data Contributor** (before capability host):
- Assigned to: AI Project managed identity
- Scope: Project storage account
- Purpose: Read/write access to blob containers

**Storage Blob Data Owner** (after capability host):
- Assigned to: AI Project managed identity
- Scope: Specific workspace container
- Purpose: Full control over workspace blobs

**Cosmos DB Operator** (before capability host):
- Assigned to: AI Project managed identity
- Scope: Cosmos DB account
- Purpose: Manage databases and containers

**Cosmos DB Built-In Data Contributor** (after capability host):
- Assigned to: AI Project managed identity
- Scope: Specific database containers
- Purpose: Read/write data in enterprise memory

**Search Index Data Contributor & Reader**:
- Assigned to: AI Project managed identity
- Scope: AI Search service
- Purpose: Create, read, update search indexes

### App Service Permissions

**AcrPull**:
- Assigned to: Web App managed identity
- Scope: Container Registry
- Purpose: Pull Docker images for deployment

## GitHub Actions Workflows

### Workflow Summary

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| Create Azure Resources | `create-foundry-infra.yml` | Manual | Deploy foundry infrastructure |
| Create Workload Infrastructure | `create-workload-infra.yml` | Manual | Deploy workload resources |
| Deploy MCP Skyrim Crime Server | `deploy-crime-function.yml` | Manual | Deploy .NET function app |
| Build and deploy Mage Guild Web Api | `deploy-mage-guild-api.yml` | Manual | Build and deploy container app |

### Environment Variables

**Common**:
- `REGION`: westus (foundry resources)
- `APP_SERVICE_REGION`: eastus2 (app service resources)
- `AZURE_CORE_OUTPUT`: none

**Function Deployment**:
- `AZURE_FUNCTIONAPP_NAME`: From secrets
- `AZURE_FUNCTIONAPP_PACKAGE_PATH`: ./src/MCP/crimeMCPServer/Crime
- `DOTNET_VERSION`: 8.0.x

### Deployment Dependencies

```
create-foundry-infra.yml
    ↓
create-workload-infra.yml
    ↓
    ├── deploy-crime-function.yml
    └── deploy-mage-guild-api.yml
```

## Tags and Metadata

Resources are tagged for organization and cost tracking:

```json
{
  "SecurityControl": "Ignore",
  "Workload": "Skyrim Crimes",
  "FoundryDependencies": "Yes"
}
```

## Cost Optimization

- **AI Search**: Standard tier (minimal replicas)
- **Cosmos DB**: Autoscale RU/s, periodic backup
- **Functions**: Flex Consumption plan
- **Storage**: Standard LRS (locally redundant)
- **App Service**: Premium V3 (for container support)

## Monitoring and Observability

All resources are connected to:
- **Log Analytics Workspace**: Centralized log collection
- **Application Insights**: Application performance monitoring, distributed tracing

Available metrics and logs:
- Function execution logs
- App Service HTTP logs
- Cosmos DB query metrics
- AI Foundry API calls
- Storage access logs

## Troubleshooting

### Common Issues

1. **Private Endpoint DNS Resolution**:
   - Ensure private DNS zones are properly configured
   - Verify DNS records for private endpoints

2. **RBAC Permissions**:
   - Some roles must be assigned before capability host creation
   - Others must be assigned after (container-level permissions)

3. **Network Connectivity**:
   - Agent subnet must be properly delegated
   - Private endpoints require correct subnet association

4. **Deployment Order**:
   - Foundry infrastructure must be deployed first
   - Workload infrastructure depends on foundry resources
   - Application deployments require infrastructure completion

## Resource Cleanup

To delete all resources:

```bash
az group delete --name rg-skyrim-world --yes --no-wait
```

⚠️ **Warning**: This will permanently delete all resources in the resource group.

## Additional Resources

- [Azure AI Foundry Documentation](https://learn.microsoft.com/azure/ai-studio/)
- [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Functions Documentation](https://learn.microsoft.com/azure/azure-functions/)

---

**Last Updated**: January 2026  
**Infrastructure Version**: 1.0  
**Maintained By**: Foundry Agentic Demo Team

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

## Deployment Process

### Prerequisites

1. Azure subscription with appropriate permissions
2. GitHub repository secrets configured:
   - `AZURE_CREDENTIALS`: Service principal credentials
   - `AZURE_SUBSCRIPTION`: Subscription ID
   - `PA_TOKEN`: Personal access token for GitHub secret management

### Deployment Stages

#### Stage 1: Foundry Infrastructure

**Workflow**: `create-foundry-infra.yml`

**How to Run**:
1. Navigate to the GitHub repository
2. Go to **Actions** tab
3. Select **Create Azure Resources** workflow
4. Click **Run workflow**
5. Choose deployment mode:
   - ✅ `use-azure-managed-ressources: true` - Azure Managed Resources (recommended)
   - ⬜ `use-azure-managed-ressources: false` - BYO (Bring Your Own) Resources

**What it Deploys**:
- Resource Group
- Virtual Network with subnets
- AI Foundry Account with model deployments (GPT-4.1-mini, text-embedding-3-large)
- AI Project workspace
- (Conditional) AI Search, Storage, Cosmos DB (if BYO mode)
- (Conditional) Private endpoints and DNS zones (if BYO mode)
- RBAC role assignments

**Outputs**: Automatically stores 13 secrets in GitHub for subsequent workflows

#### Stage 2: Workload Infrastructure

**Workflow**: `create-workload-infra.yml`

**How to Run**:
1. Navigate to the GitHub repository
2. Go to **Actions** tab
3. Select **Create Workload Infrastructure** workflow
4. Click **Run workflow**

**Prerequisites**: Stage 1 must be completed first

**What it Deploys**:
- Cosmos DB (crime database with vector search)
- Azure Storage (workload data)
- Azure Functions infrastructure (Crime MCP Server)
- Container Registry
- App Service Plan and Web App (Mage Guild API)
- Log Analytics and Application Insights
- Foundry IQ Search instance
- RBAC role assignments

**Outputs**: Stores 3 additional secrets for application deployments

#### Stage 3: Deploy Crime Function

**Workflow**: `deploy-crime-function.yml`

**How to Run**:
1. Navigate to the GitHub repository
2. Go to **Actions** tab
3. Select **Deploy MCP Skyrim Crime Server** workflow
4. Click **Run workflow**

**Prerequisites**: Stage 2 must be completed first

**What it Does**:
- Builds the .NET 8.0 Crime MCP Server
- Deploys to Azure Functions (Flex Consumption plan)

**Source Code**: `./src/MCP/crimeMCPServer/Crime`

#### Stage 4: Deploy Mage Guild API

**Workflow**: `deploy-mage-guild-api.yml`

**How to Run**:
1. Navigate to the GitHub repository
2. Go to **Actions** tab
3. Select **Build and deploy Mage Guild Web Api** workflow
4. Click **Run workflow**

**Prerequisites**: Stage 2 must be completed first

**What it Does**:
- Builds Docker container image in Azure Container Registry
- Deploys container to App Service

**Source Code**: `./src/apis/mage-guild-api`

### Deployment Order

```
1. create-foundry-infra.yml
        ↓
2. create-workload-infra.yml
        ↓
        ├── 3. deploy-crime-function.yml
        └── 4. deploy-mage-guild-api.yml
```

**⚠️ Important**: Stages 3 and 4 can run in parallel after Stage 2 completes.

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

---

**Last Updated**: January 2026  
**Infrastructure Version**: 1.0  
**Maintained By**: Foundry Agentic Demo Team

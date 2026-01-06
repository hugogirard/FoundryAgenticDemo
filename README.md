# Foundry Agentic Demo - Skyrim Crime Tracking System

An AI-powered crime tracking system for the world of Skyrim, demonstrating Azure AI Foundry capabilities with AI agents, vector search, and modern cloud infrastructure.

## � Getting Started

Follow these steps to deploy and configure the Skyrim Crime Tracking System:

### **Step 1: Infrastructure Setup**
📖 **[Start here: Infrastructure Documentation](documents/INFRASTRUCTURE.md)**

Deploy the complete Azure infrastructure including Azure AI Foundry, Cosmos DB, AI Search, and all supporting services. This guide covers:
- Architecture overview and components
- Deployment process with GitHub Actions
- Network configuration and security
- Resource configuration details

### **Step 2: Crime Data Configuration**
📖 **[Next: Crime Data Setup Guide](documents/CRIME.MD)**

After infrastructure deployment, populate the crime database and configure search capabilities. This guide covers:
- Uploading crime data to Cosmos DB
- Configuring full-text search and indexing
- Testing data queries and search functionality

## 📁 Project Structure

```
FoundryAgenticDemo/
├── documents/              # Documentation
│   ├── INFRASTRUCTURE.md   # Step 1: Infrastructure deployment
│   └── CRIME.MD            # Step 2: Crime data setup
├── infra/                  # Bicep infrastructure templates
├── src/                    # Source code (agents, APIs, MCP servers)
├── notebook/               # Jupyter notebooks
├── scripts/                # Utility scripts
├── dataset/                # Sample crime data
└── .github/workflows/      # CI/CD pipelines
```

## 📚 Full Documentation

All detailed documentation is available in the `documents/` folder:

- **[Infrastructure Documentation](documents/INFRASTRUCTURE.md)** - Complete guide to Azure infrastructure, Bicep templates, deployment process, network architecture, and GitHub Actions workflows
- **[Crime Data Setup Guide](documents/CRIME.MD)** - Instructions for uploading crime data to Cosmos DB and configuring full-text search

---

**Last Updated**: January 2026

param foundryResourceName string
param crimeMCPServerResourceName string

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: foundryResourceName
}

resource mcpConnections 'Microsoft.CognitiveServices/accounts/connections@2025-10-01-preview' = {
  parent: foundryAccount
  name: 'mcpCrimeServerConnections'
  properties: {
    authType: 'CustomKeys'
    category: 'RemoteTool'
    target: crimeMCPServerResourceName
    useWorkspaceManagedIdentity: false
    isSharedToAll: false
    metadata: {
      type: 'custom_MCP'
    }
  }
}

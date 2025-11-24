/*
Virtual Network Module
This module deploys the core network infrastructure with security controls:

1. Address Space:
   - VNet CIDR: 172.16.0.0/16 OR 192.168.0.0/16
   - Agents Subnet: 172.16.0.0/24 OR 192.168.0.0/24
   - Private Endpoint Subnet: 172.16.101.0/24 OR 192.168.1.0/24

2. Security Features:
   - Network isolation
   - Subnet delegation
   - Private endpoint subnet
*/

param location string

var agentSubnetName = 'agent-subnet'
var peSubnetName = 'pe-subnet'
var vnetName = 'vnet-agent'

var vnetAddress = '192.168.0.0/16'
var agentSubnet = cidrSubnet(vnetAddress, 24, 0)
var peSubnet = cidrSubnet(vnetAddress, 24, 1)

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddress
      ]
    }
    subnets: [
      {
        name: agentSubnetName
        properties: {
          addressPrefix: agentSubnet
          delegations: [
            {
              name: 'Microsoft.app/environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
      {
        name: peSubnetName
        properties: {
          addressPrefix: peSubnet
        }
      }
    ]
  }
}

// Output variables
output peSubnetName string = peSubnetName
output agentSubnetName string = agentSubnetName
output agentSubnetId string = '${virtualNetwork.id}/subnets/${agentSubnetName}'
output peSubnetId string = '${virtualNetwork.id}/subnets/${peSubnetName}'
output virtualNetworkName string = virtualNetwork.name
output virtualNetworkId string = virtualNetwork.id
output virtualNetworkResourceGroup string = resourceGroup().name
output virtualNetworkSubscriptionId string = subscription().subscriptionId

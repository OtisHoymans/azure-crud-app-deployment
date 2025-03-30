//Location for all the resources. 
param location string = resourceGroup().location

//Prefix used for resource naming. 
param projectPrefix string = 'crudapp'

// Variables for consistent naming within resources. 
var vnetName = '${projectPrefix}vnet'
var subnetContainerName = '${projectPrefix}subnet-container'
var subnetAppGwName = '${projectPrefix}subnet-appgw'
var nsgName = '${projectPrefix}nsg'
var logWorkspaceName = '${projectPrefix}logworkspace'

// Network Security Group (NSG)
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPInbound' //Rule to allow HTTP inbound traffic. 
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80' //Allow traffic on HTTP port 80. 
        }
      }
    ]
  }
}

// Virtual Network with Separate Subnets for ACI and App Gateway
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: subnetContainerName //Subnet for container instances. 
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
          delegations: [
            {
              name: 'aciDelegation' //Delegating subnet to Azure Container Instances. 
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
      {
        name: subnetAppGwName //Subnet for application gateway. 
        properties: {
          addressPrefix: '10.0.2.0/24' 
        }
      }
    ]
  }
}

// Public IP for Application Gateway
resource appGatewayPublicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: '${projectPrefix}-appgw-pip'
  location: location
  sku: {
    name: 'Standard' //Standard SKU pricing tier for Public IP. 
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Log Analytics Workspace
resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018' //Pricing tier for Log Analytics Workspace. 
    }
    retentionInDays: 30 //Logs are retained for 30 days. 
  }
}

// Outputs to use in the next deployment
output vnetName string = vnetName
output subnetContainerName string = subnetContainerName
output subnetAppGwName string = subnetAppGwName
output logWorkspaceId string = logWorkspace.properties.customerId
output logWorkspaceKey string = logWorkspace.listKeys().primarySharedKey
output publicIpId string = appGatewayPublicIP.id
output publicIpAddress string = appGatewayPublicIP.properties.ipAddress

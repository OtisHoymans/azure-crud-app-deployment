//Location for all resources. 
param location string = resourceGroup().location

//Prefix to use for resource naming. 
param projectPrefix string = 'crudapp'

//Container image tag. 
param imageTag string = 'v1'

//Name of the created ACR login server. 
param acrLoginServer string = 'acroh.azurecr.io'

//Resource group name for the ACR. 
param resourceGroupName string = 'crudapp-rg'

//Name of created VNET in infra.bicep. 
param vnetName string = '${projectPrefix}vnet'

//Name of container subnet created in infra.bicep. 
param subnetContainerName string = '${projectPrefix}subnet-container'

//Name of App Gateway subnet created in infra.bicep. 
param subnetAppGwName string  = '${projectPrefix}subnet-appgw'

//Log Analytics Workspace ID. 
param logWorkspaceId string = '${projectPrefix}logworkspace'

//Initialization of Log Analytics Workspace Key. 
@secure()
param logWorkspaceKey string 

//Initialization of public IP resource ID. 
param publicIpId string

var containerName = '${projectPrefix}container'
var containerImageName = 'crud-flask-app'
var frontendPortName = 'frontendPort'

// Extract ACR name - first part of the login server before first dot
var acrName = first(split(acrLoginServer, '.'))

// Azure Container Registry (ACR) - Referencing the exisitng resource. 
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: acrName
  scope: resourceGroup(subscription().subscriptionId, resourceGroupName)
}

// Azure Container Instance (ACI) deployment
resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: containerName
  location: location
  properties: {
    containers: [
      {
        name: containerName
        properties: {
          image: '${acrLoginServer}/${containerImageName}:${imageTag}' //Container image with tag. 
          ports: [{ port: 80, protocol: 'TCP' }] //Exposing port 80 for HTTP traffic. 
          resources: { requests: { cpu: 1, memoryInGB: 1 } } //CPU & Memory allocation of the container. 
        }
      }
    ]
    osType: 'Linux'
    ipAddress: {
      type: 'Private' //Private IP, app will be made public via App Gateway. 
      ports: [
        {
          port: 80
          protocol: 'TCP'
        }
      ]
    }
    diagnostics: {
      logAnalytics: {
        workspaceId: logWorkspaceId
        workspaceKey: logWorkspaceKey
      }
    }
    imageRegistryCredentials: [ //ACR authentication details, this makes sure the container can access the image. 
      {
        server: acrLoginServer
        username: acr.listCredentials().username
        password: acr.listCredentials().passwords[0].value
      }
    ]
    subnetIds: [ //Attaches container to the designated subnet. 
      {
        id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetContainerName)
      }
    ]
  }
}

// Application Gateway deployment
resource appGateway 'Microsoft.Network/applicationGateways@2023-05-01' = {
  name: '${projectPrefix}-appgateway'
  location: location
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 2 //Defines the number of instances. 
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIPConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetAppGwName)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: publicIpId //Attaches the Public IP to App Gateway. 
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: frontendPortName
        properties: {
          port: 80 //Listening on port 80. 
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backendPool'
        properties: {
          backendAddresses: [
            {
              ipAddress: containerGroup.properties.ipAddress.ip //Uses the contianer's private IP. 
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'httpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 30
          pickHostNameFromBackendAddress: false
        }
      }
    ]
    httpListeners: [
      {
        name: 'httpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', '${projectPrefix}-appgateway', 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', '${projectPrefix}-appgateway', frontendPortName)
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'routingRule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', '${projectPrefix}-appgateway', 'httpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', '${projectPrefix}-appgateway', 'backendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', '${projectPrefix}-appgateway', 'httpSettings')
          }
        }
      }
    ]
  }
}

output containerIp string = containerGroup.properties.ipAddress.ip 
output appGatewayName string = appGateway.name 

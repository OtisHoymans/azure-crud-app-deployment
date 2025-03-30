// Define required parameters
param location string = resourceGroup().location //Location for resource deployment. 
param acrLoginServer string 

//Deployment of the infrastructure module: Networking (VNET), NSG, Public IP & Log Analytics. 
module infra './infra.bicep' = {
  name: 'infra-deployment'
  params: {
    location: location
  }
}

//Deployment of the application module: Container instance & Application Gateway. 
module app './app.bicep' = {
  name: 'app-deployment'
  params: {
    location: location
    acrLoginServer: acrLoginServer
    vnetName: infra.outputs.vnetName
    subnetContainerName: infra.outputs.subnetContainerName
    subnetAppGwName: infra.outputs.subnetAppGwName
    logWorkspaceId: infra.outputs.logWorkspaceId
    logWorkspaceKey: infra.outputs.logWorkspaceKey
    publicIpId: infra.outputs.publicIpId
  }
}

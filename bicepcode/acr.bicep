// 1. acr.bicep - Deploy this first!

// Location for all resources.
param location string = resourceGroup().location

// Variables to define a consistent name for the ACR. Change this to change the name of the ACR itself. 
var acrName = 'acroh'

// Define an Azure Container Registry resource. 
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic' //Pricing tier for the ACR, set to basic. 
  }
  properties: {
    adminUserEnabled: true //Enables admin user permissions for ACR. 
  }
}


// Outputs for use in next deployment command. 
output acrLoginServer string = acr.properties.loginServer
output acrName string = acr.name


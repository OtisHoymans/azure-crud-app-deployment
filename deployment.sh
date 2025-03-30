#!/bin/bash

# Create a resource group where our resources will be stored. 
az group create --name crudapp-rg --location eastus  

# Create the ACR by deploying the acr.bicep template.
az deployment group create --resource-group crudapp-rg --template-file acr.bicep

# Get the ACR login server and name after the deployment is successful
ACR_LOGIN_SERVER=$(az deployment group show --resource-group crudapp-rg --name $(az deployment group list --resource-group crudapp-rg --query "[0].name" -o tsv) --query "properties.outputs.acrLoginServer.value" -o tsv)

ACR_NAME=$(az deployment group show --resource-group crudapp-rg --name $(az deployment group list --resource-group crudapp-rg --query "[0].name" -o tsv) --query "properties.outputs.acrName.value" -o tsv)

# Log in to ACR so the image can be built and pushed to it.
az acr login --name $ACR_NAME

# Build and push the Docker image to ACR.
docker build -t $ACR_LOGIN_SERVER/crud-flask-app:v1 .
docker push $ACR_LOGIN_SERVER/crud-flask-app:v1

# Display the ACR login server and name.
echo "ACR Login Server: $ACR_LOGIN_SERVER"
echo "ACR Name: $ACR_NAME"

# Deploy the 'main.bicep' template, which deploys 'infra.bicep' and 'app.bicep' to finally deploy the application on Azure. 
az deployment group create --resource-group crudapp-rg --template-file main.bicep --parameters acrLoginServer=$ACR_LOGIN_SERVER

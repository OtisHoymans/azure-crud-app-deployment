#Run this file with 'sh deployment.sh' to fully deploy the application on Azure.

#Create a resource group where our resources will be stored. 
az group create --name crudapp-rg --location eastus  

#Create the ACR by deploying the acr.bicep template. 
az deployment group create --resource-group crudapp-rg --template-file acr.bicep

# Log in to ACR so the image can be built and pushed to it. 
az acr login --name $ACR_NAME

# Build and push the image. 
docker build -t $ACR_LOGIN_SERVER/crud-flask-app:v1 .
docker push $ACR_LOGIN_SERVER/crud-flask-app:v1

#The ACR login server and name.  
echo "ACR Login Server: $ACR_LOGIN_SERVER"
echo "ACR Name: $ACR_NAME"

#Deploy the 'main.bicep' template, which deploys 'infra.bicep' and 'app.bicep' to finally deploy the application on Azure. 
az deployment group create --resource-group crudapp-rg --template-file main.bicep --parameters acrLoginServer=acroh.azurecr.io 
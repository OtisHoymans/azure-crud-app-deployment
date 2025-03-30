# Assignment 2: Azure Infrastructure-as-Code (10% PE) - Cloud Platforms

## Introduction
This project was made by Otis Hoymans, a second year Cloud & Cybersecurity student at Thomas More Geel. It focuses on deploying a CRUD application to Azure using Infrastructure-as-Code (IaC) principles with Bicep templates. The goal is to design and implement a cloud-based deployment architecture while following the best IaC practices to automate the process as much as possible.

## Azure Design Diagram



## How the Application Works
The application is a Flask-based CRUD app running inside a Docker container, deployed to Azure using Azure Container Instances (ACI). It allows users to perform Create, Read, Update, and Delete (CRUD) operations via a web interface. The application is exposed to the internet via an Azure Application Gateway, which routes traffic to the container instance securely.

## Deployment Instructions

### Running the Deployment Script
To deploy the application, execute the provided `deployment.sh` script:

```sh
sh deployment.sh
```

This script will:
1. **Create a Resource Group**: All Azure resources will be deployed inside `crudapp-rg`.
2. **Deploy Azure Container Registry (ACR)**: The script deploys `acr.bicep` to create the ACR.
3. **Log in to ACR**: Ensures access to push the container image.
4. **Build and Push the Image**: Builds the Docker container image and uploads it to ACR.
5. **Deploy the Infrastructure and Application**: Deploys `main.bicep`, which provisions all required resources, including networking and application deployment.

### Accessing the Application
Once deployed, retrieve the public IP address of the application gateway:

```sh
az network public-ip list --resource-group crudapp-rg --query "[].{name:name, ipAddress:ipAddress}" --output table
```

Then, open your browser and navigate to:
```
http://<public-ip>
```

---



#!/usr/bin/env bash
set -euo pipefail

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

RESOURCE_GROUP="${RESOURCE_GROUP:-rg-aspire-demo}"
LOCATION="${LOCATION:-westeurope}"
ENVIRONMENT="${ENVIRONMENT:-env-aspire}"
LOG_ANALYTICS="${LOG_ANALYTICS:-log-aspire}"
ACR_NAME="${ACR_NAME:-acraspiredemo}"
IMAGE_TAG="${IMAGE_TAG:-v1.0.0}"
PORT_WEB="${PORT_WEB:-8080}"
PORT_API="${PORT_API:-8081}"

echo "Logging into Azure..."
az login --only-show-errors
az account set --subscription "${AZURE_SUBSCRIPTION_ID:-<your-subscription-id>}"

echo "Creating resource group..."
az group create -n $RESOURCE_GROUP -l $LOCATION

echo "Creating Log Analytics workspace..."
az monitor log-analytics workspace create -g $RESOURCE_GROUP -n $LOG_ANALYTICS -l $LOCATION

LOG_ID=$(az monitor log-analytics workspace show -g $RESOURCE_GROUP -n $LOG_ANALYTICS --query id -o tsv)

echo "Creating Container Apps environment..."
az containerapp env create -g $RESOURCE_GROUP -n $ENVIRONMENT -l $LOCATION --logs-workspace-id $LOG_ID

echo "Creating Azure Container Registry..."
az acr create -g $RESOURCE_GROUP -n $ACR_NAME --sku Basic -l $LOCATION
ACR_LOGIN_SERVER=$(az acr show -n $ACR_NAME --query loginServer -o tsv)
az acr login -n $ACR_NAME

echo "Building AspireStarterApp containers..."
docker build -f ./AspireStarterApp.Web/Dockerfile -t $ACR_LOGIN_SERVER/aspire-web:$IMAGE_TAG ./AspireStarterApp.Web
docker build -f ./AspireStarterApp.API/Dockerfile -t $ACR_LOGIN_SERVER/aspire-api:$IMAGE_TAG ./AspireStarterApp.API

docker push $ACR_LOGIN_SERVER/aspire-web:$IMAGE_TAG
docker push $ACR_LOGIN_SERVER/aspire-api:$IMAGE_TAG

REG_USER=$(az acr credential show -n $ACR_NAME --query username -o tsv)
REG_PASS=$(az acr credential show -n $ACR_NAME --query passwords[0].value -o tsv)

echo "Deploying Aspire Web..."
az containerapp create   -g $RESOURCE_GROUP   -n aspire-web   --environment $ENVIRONMENT   --image $ACR_LOGIN_SERVER/aspire-web:$IMAGE_TAG   --ingress external   --target-port $PORT_WEB   --registry-server $ACR_LOGIN_SERVER   --registry-username $REG_USER   --registry-password $REG_PASS   --query properties.configuration.ingress.fqdn -o tsv

echo "Deploying Aspire API..."
az containerapp create   -g $RESOURCE_GROUP   -n aspire-api   --environment $ENVIRONMENT   --image $ACR_LOGIN_SERVER/aspire-api:$IMAGE_TAG   --ingress internal   --target-port $PORT_API   --registry-server $ACR_LOGIN_SERVER   --registry-username $REG_USER   --registry-password $REG_PASS

echo "✅ Aspire Starter App deployed successfully!"

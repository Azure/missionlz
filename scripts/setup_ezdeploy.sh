#!/bin/bash

# This script deploys the following items to the subscription (Likely to be merged with setupTerraformStorage)
# - vnet
# - image registry
# - docker instance

# Additionally this script builds the docker image prior to deploying the instance and pushes it to the 

resource_group_name=rg-terraform
region=eastus
acr_name $(echo "mlzregistry${subscription_id: -12}")
instance_name $(echo "mlz${subscription_id: -12}")
keyvault_name $(echo "tfkv${subscription_id: -13}")
tf_service_principal_name $(echo "http://tfsp.$subscription_id")
metadata="missionlztype=deploy"
single_tag="missionlz"
tags="$single_tag $metadata" # All other objects allow tags with and without values.

echo "INFO: Setting current az cli subscription to '$subscription_id'"
az account set --subscription $subscription_id

echo "INFO: creating registry"
az acr create \
 --resource-group $resource_group_name \
 --name $acr_name \
 --sku Basic \
 --tags $tags

az acr update --name $acr_name --admin-enabled true

#echo "Adding service principal to ACR permissions"
ACR_REGISTRY_ID=$(az acr show --name $acr_name --query id --output tsv)

echo "INFO: building docker container"
docker build -t lzfront ./../

echo "INFO: Logging into Container Registry"
az acr login --name $acr_name

echo "INFO: pushing docker container"
docker tag lzfront:latest $acr_name.azurecr.io/lzfront:latest
docker push $acr_name.azurecr.io/lzfront:latest
ACR_LOGIN_SERVER=$(az acr show --name $acr_name --resource-group $resource_group_name --query "loginServer" --output tsv)

echo "INFO: creating instance"
cont_ip=$(az container create \
 --resource-group $resource_group_name \
 --name $instance_name \
 --image $ACR_LOGIN_SERVER/lzfront:latest \
 --dns-name-label mlz-deployment-${subscription_id: -13} \
 --registry-login-server $ACR_LOGIN_SERVER \
 --registry-username $(az keyvault secret show --name "mlz-spn-uid" --vault-name $keyvault_name --query value --output tsv) \
 --registry-password $(az keyvault secret show --name "mlz-spn-pword" --vault-name $keyvault_name --query value --output tsv) \
 --ports 80 \
 --query ipAddress.fqdn \
 --assign-identity
 --output tsv)

echo "INFO: Giving Instance the necessary permissions"
az keyvault set-policy \
 -n $keyvault_name \
  --key-permissions get list \
  --secret-permissions get list \
  --object-id $(az container show --resource-group $resource_group_name --name $instance_name --query identity.principalId --output tsv)

echo "INFO: done, configuration options available at $cont_ip"
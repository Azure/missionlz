#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC1091
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC1091: Not following. Shellcheck can't follow non-constant source.
#
# This script deploys container registries, app registrations, and a container instance to run the MLZ front end

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "setup_ezdeploy.sh: Setup the Front End for MLZ"
  error_log "usage: setup_ezdeploy.sh subscription_id tenant_id <tf_env_name {{default=public}}> <mlz_env_name {{default=mlzdeployment}}> 

  "
}

if [[ "$#" -lt 2 ]]; then
   usage
   exit 1
fi

# FrontEnd ByPasses
# Note: We use this to provide the variables required to execute name generation to be used here.  Otherwise we would need to source a config that might not be setup yet.
docker_strategy=${1}
export mlz_config_subid=${2}
export mlz_tenantid=${3}
export tf_environment=${4:-public}
export mlz_env_name=${5:-mlzdeployment}
# Needed for the creation script
export mlz_tier0_subid=${2}
export mlz_tier1_subid=${2}
export mlz_tier2_subid=${2}
export mlz_saca_subid=${2}

# generate MLZ configuration names
. "${BASH_SOURCE%/*}/generate_names.sh bypass"


echo "INFO: Setting current az cli subscription to '$subscription_id'"
az account set --subscription $subscription_id

## Handle Docker Building ACR resources first
if [[ $docker_strategy != "local" ]]; then
  echo "Creating ACR"
  az acr create \
  --resource-group ${mlz_rg_name} \
  --name ${mlz_acr_name} \
  --sku Basic 

  echo "Running post process to enable admin on ACR"
  az acr update --name "${mlz_acr_name}" --admin-enabled true

  . "${BASH_SOURCE%/*}/ezdeploy_docker.sh $docker_strategy"

  docker tag lzfront:latest "${mlz_acr_name}.azurecr.io/lzfront:latest"

fi








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
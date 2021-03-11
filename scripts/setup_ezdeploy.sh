#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC1091
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC1091: Not following. Shellcheck can't follow non-constant source.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# This script deploys container registries, app registrations, and a container instance to run the MLZ front end

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "setup_ezdeploy.sh: Setup the Front End for MLZ"
  error_log "usage: setup_ezdeploy.sh subscription_id tenant_id <tf_env_name {{default=public}}> <mlz_env_name {{default=mlzdeployment}}> "
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

fqdn="localhost"

# generate MLZ configuration names
. "${BASH_SOURCE%/*}/generate_names.sh bypass"


echo "INFO: Setting current az cli subscription to ${mlz_config_subid}"
az account set --subscription "${mlz_config_subid}"

# Handle Deployment of Login Services

# Handle Remote Deploy to a Container Instance
if [[ $docker_strategy != "local" ]]; then
  echo "Creating ACR"
  az acr create \
  --resource-group "${mlz_rg_name}" \
  --name "${mlz_acr_name}" \
  --sku Basic 

  echo "Running post process to enable admin on ACR"
  az acr update --name "${mlz_acr_name}" --admin-enabled true

  . "${BASH_SOURCE%/*}/ezdeploy_docker.sh $docker_strategy"

  docker tag lzfront:latest "${mlz_acr_name}.azurecr.io/lzfront:latest"

    echo "INFO: Logging into Container Registry"
    az acr login --name "${mlz_acr_name}"

    echo "INFO: pushing docker container"
    docker tag lzfront:latest "${mlz_acr_name}".azurecr.io/lzfront:latest
    docker push "${mlz_acr_name}".azurecr.io/lzfront:latest
    ACR_LOGIN_SERVER=$(az acr show --name "${mlz_acr_name}" --resource-group "${mlz_rg_name}"--query "loginServer" --output tsv)

    echo "INFO: creating instance"
    fqdn=$(az container create \
    --resource-group "${mlz_rg_name}"\
    --name "${mlz_instance_name}" \
    --image "$ACR_LOGIN_SERVER"/lzfront:latest \
    --dns-name-label mlz-deployment-"${mlz_config_subid}" \
    --registry-login-server "$ACR_LOGIN_SERVER" \
    --registry-username "$(az keyvault secret show --name "mlz-spn-uid" --vault-name "${mlz_kv_name}" --query value --output tsv)" \
    --registry-password "$(az keyvault secret show --name "mlz-spn-pword" --vault-name "${mlz_kv_name}" --query value --output tsv)" \
    --ports 80 \
    --query ipAddress.fqdn \
    --assign-identity
    --output tsv)

    echo "INFO: Giving Instance the necessary permissions"
    az keyvault set-policy \
    -n "${mlz_kv_name}" \
      --key-permissions get list \
      --secret-permissions get list \
      --object-id "$(az container show --resource-group "${mlz_rg_name}" --name "${mlz_instance_name}" --query identity.principalId --output tsv)"
    #TODO we need the unique domain name instead!
    echo "INFO: Front End is deployed at $fqdn"

fi

# Generate the Login EndPoint for Security Purposes
echo "Creating App Registration to facilitate login capabilities"
client_password=$(az ad app credential reset \
      --id "$(az ad app create \
        --display-name "${mlz_fe_app_name}" \
        --reply-urls "http://$fqdn/redirect" \
        --required-resource-accesses  ./config/mlz_login_app_resources.json \
        --query appId \
        --output tsv)" \
        --query password \
        --output tsv)

az keyvault secret set \
    --name "${mlz_login_app_kv_password}" \
    --subscription "${mlz_config_subid}" \
    --vault-name "${mlz_kv_name}" \
    --value "$client_password" \
    --output none
echo "KeyVault updated with Login App Registration secret!"





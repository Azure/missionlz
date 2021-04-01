#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC1091,2154
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
  error_log "usage: setup_ezdeploy.sh -d <local|build|load> -s <subscription_id> -t <tenant_id> -l <location> -e <tf_env_name {{default=public}}> -m <mlz_env_name {{default=mlzdeployment}}> -p <web_port {{default=80}}> -0 <saca_subscription_id> -1 <tier0_subscription_id> -2 <tier1_subscription_id> -3 <tier2_subscription_id>"
}

if [[ "$#" -lt 8 ]]; then
   usage
   exit 1
fi

metadata_host="management.azure.com" # TODO (20210401): pass this by parameter or derive from cloud

tf_environment=public
mlz_env_name=mlzdeployment
web_port=80
subs=()

while getopts "d:s:t:l:e:m:p:0:1:2:3:4:" opts; do
  case "${opts}" in
    d) docker_strategy=${OPTARG}
      ;;
    s) mlz_config_subid=${OPTARG}
      subs+=("${OPTARG}")
      ;;
    t) mlz_tenantid=${OPTARG}
      ;;
    l) mlz_config_location=${OPTARG}
      ;;
    e) tf_environment=${OPTARG}
      ;;
    m) mlz_env_name=${OPTARG}
      ;;
    p) web_port=${OPTARG}
      ;;
    0) mlz_saca_subid=${OPTARG}
      subs+=("${OPTARG}")
      ;;
    1) mlz_tier0_subid=${OPTARG}
      subs+=("${OPTARG}")
      ;;
    2) mlz_tier1_subid=${OPTARG}
      subs+=("${OPTARG}")
      ;;
    3) mlz_tier2_subid=${OPTARG}
      subs+=("${OPTARG}")
      ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      exit 2
      ;;
  esac
done

# create 'src/mlz.config' file
src_path=$(dirname "$(realpath "${BASH_SOURCE%/*}")")
mlz_config_file="${src_path}/mlz.config"

. "${BASH_SOURCE%/*}/config/generate_config_file.sh" \
    "$mlz_config_file" \
    "$tf_environment" \
    "$metadata_host" \
    "$mlz_env_name" \
    "$mlz_config_location" \
    "$mlz_config_subid" \
    "$mlz_tenantid" \
    "$mlz_saca_subid" \
    "$mlz_tier0_subid" \
    "$mlz_tier1_subid" \
    "$mlz_tier2_subid"

# generate MLZ configuration names
. "${BASH_SOURCE%/*}/config/generate_names.sh" "$mlz_config_file"

echo "INFO: Setting current az cli subscription to ${mlz_config_subid}"
az account set --subscription "${mlz_config_subid}"

if [[ $docker_strategy != "build" && \
      $docker_strategy != "load" && \
      $docker_strategy != "local" ]]; then
  error_log "Unrecognized docker strategy detected. Must be 'local', 'build', or 'load'."
fi

if [[ $docker_strategy == "build" ]]; then
  echo "do work"
  # create ACR
  # build image
  # deploy instance
  # add permissions
  # get URL
fi

if [[ $docker_strategy == "load" ]]; then
  echo "do work"
  # ???
fi

if [[ $docker_strategy == "local" ]]; then
  echo "do work"
  # set env vars
fi

# # Handle Remote Deploy to a Container Instance
# if [[ $docker_strategy != "local" ]]; then
#   echo "Creating ACR"
#   az acr create \
#   --resource-group "${mlz_rg_name}" \
#   --name "${mlz_acr_name}" \
#   --sku Basic

#   echo "Waiting for registry completion and running post process to enable admin on ACR"
#   sleep 60
#   az acr update --name "${mlz_acr_name}" --admin-enabled true

#   . "${BASH_SOURCE%/*}/ezdeploy_docker.sh" "$docker_strategy"

#   docker tag lzfront:latest "${mlz_acr_name}.azurecr.io/lzfront:latest"

#   echo "INFO: Logging into Container Registry"
#   az acr login --name "${mlz_acr_name}"

#   ACR_REGISTRY_ID=$(az acr show --name "${mlz_acr_name}" --query id --output tsv)
#   az role assignment create --assignee "$(az keyvault secret show --name "${mlz_sp_kv_name}" --vault-name "${mlz_kv_name}" --query value --output tsv)" --scope "${ACR_REGISTRY_ID}" --role acrpull

#   echo "INFO: pushing docker container"
#   docker tag lzfront:latest "${mlz_acr_name}".azurecr.io/lzfront:latest
#   docker push "${mlz_acr_name}".azurecr.io/lzfront:latest
#   ACR_LOGIN_SERVER=$(az acr show --name "${mlz_acr_name}" --resource-group "${mlz_rg_name}" --query "loginServer" --output tsv)

#   echo "INFO: creating instance"
#   fqdn=$(az container create \
#   --resource-group "${mlz_rg_name}"\
#   --name "${mlz_instance_name}" \
#   --image "$ACR_LOGIN_SERVER"/lzfront:latest \
#   --dns-name-label "${mlz_dns_name}" \
#   --environment-variables KEYVAULT_ID="${mlz_kv_name}" TENANT_ID="${mlz_tenantid}" MLZ_LOCATION="${mlz_config_location}" SUBSCRIPTION_ID="${mlz_config_subid}" TF_ENV="${tf_environment}" MLZ_ENV="${mlz_env_name}" \
#   --registry-username "$(az keyvault secret show --name "${mlz_sp_kv_name}" --vault-name "${mlz_kv_name}" --query value --output tsv)" \
#   --registry-password "$(az keyvault secret show --name "${mlz_sp_kv_password}" --vault-name "${mlz_kv_name}" --query value --output tsv)" \
#   --ports 80 \
#   --query ipAddress.fqdn \
#   --assign-identity \
#   --output tsv)

#   echo "INFO: Giving Instance the necessary permissions"
#   az keyvault set-policy \
#   -n "${mlz_kv_name}" \
#     --key-permissions get list \
#     --secret-permissions get list \
#     --object-id "$(az container show --resource-group "${mlz_rg_name}" --name "${mlz_instance_name}" --query identity.principalId --output tsv)"
# else
#   fqdn="localhost"
# fi

# if [[ $web_port != 80 ]]; then
#   fqdn+=":$web_port"
# fi


# # Generate the Login EndPoint for Security Purposes
# echo "Creating App Registration to facilitate login capabilities"
# client_id=$(az ad app create \
#         --display-name "${mlz_fe_app_name}" \
#         --reply-urls "http://$fqdn/redirect" \
#         --required-resource-accesses  "${BASH_SOURCE%/*}"/config/mlz_login_app_resources.json \
#         --query appId \
#         --output tsv)

# client_password=$(az ad app credential reset \
#       --id "$client_id" \
#         --query password \
#         --output tsv)

# echo "Storing client id at ${mlz_login_app_kv_name}"
# az keyvault secret set \
#     --name "${mlz_login_app_kv_name}" \
#     --subscription "${mlz_config_subid}" \
#     --vault-name "${mlz_kv_name}" \
#     --value "$client_id" \
#     --output none

# echo "Storing client secret at ${mlz_login_app_kv_password}"
# az keyvault secret set \
#     --name "${mlz_login_app_kv_password}" \
#     --subscription "${mlz_config_subid}" \
#     --vault-name "${mlz_kv_name}" \
#     --value "$client_password" \
#     --output none

# echo "KeyVault updated with Login App Registration secret!"
# echo "All steps have been completed you will need the following to access the configuration utility:"

# if [[ $docker_strategy == "local" ]]; then
#   echo "Your environment variables for local execution are:"
#   echo "Copy-Paste:"
#   echo "Bash:"
#   echo "export CLIENT_ID=$client_id"
#   echo "export CLIENT_SECRET=$client_password"
#   echo "export TENANT_ID=$mlz_tenantid"
#   echo "export LOCATION=$mlz_config_location"
#   echo "export SUBSCRIPTION_ID=$mlz_config_subid"
#   echo "export TF_ENV=$tf_environment"
#   echo "export MLZ_ENV=$mlz_env_name"
#   echo "export MLZCLIENTID=$(az keyvault secret show --name "${mlz_sp_kv_name}" --vault-name "${mlz_kv_name}" --query value --output tsv)"
#   echo "export MLZCLIENTSECRET=$(az keyvault secret show --name "${mlz_sp_kv_password}" --vault-name "${mlz_kv_name}" --query value --output tsv)"
#   echo "Powershell:"
#   echo "\$env:CLIENT_ID='$client_id'"
#   echo "\$env:CLIENT_SECRET='$client_password'"
#   echo "\$env:TENANT_ID='$mlz_tenantid'"
#   echo "\$env:LOCATION='$mlz_config_location'"
#   echo "\$env:SUBSCRIPTION_ID='$mlz_config_subid'"
#   echo "\$env:TF_ENV='$tf_environment'"
#   echo "\$env:MLZ_ENV='$mlz_env_name'"
#   echo "\$env:MLZCLIENTID='$(az keyvault secret show --name "${mlz_sp_kv_name}" --vault-name "${mlz_kv_name}" --query value --output tsv)'"
#   echo "\$env:MLZCLIENTSECRET='$(az keyvault secret show --name "${mlz_sp_kv_password}" --vault-name "${mlz_kv_name}" --query value --output tsv)'"
# else
#   echo "You can access the front end at http://$fqdn"
# fi
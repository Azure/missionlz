#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC2154
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# deploy a docker image to Azure Container Registry that hosts the MLZ UI

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "deploy_instance.sh: deploy a docker image to Azure Container Registry that hosts the MLZ UI"
  error_log "usage: deploy_instance.sh <mlz config file> <image name> <image tag>"
}

if [[ "$#" -lt 3 ]]; then
   usage
   exit 1
fi

mlz_config_file=$1
image_name=$2
image_tag=$3

# generate MLZ configuration names
. "${mlz_config_file}"
. "$(dirname "$(realpath "${BASH_SOURCE%/*}")")/config/generate_names.sh" "${mlz_config_file}"

acr_login_server=$(az acr show \
  --name "${mlz_acr_name}" \
  --resource-group "${mlz_rg_name}" \
  --query "loginServer" \
  --output tsv)

echo "INFO: creating instance of ${image_name}:${image_tag} on ${mlz_instance_name} in ${mlz_acr_name}..."

registry_username=$(az keyvault secret show \
  --name "${mlz_sp_kv_name}" \
  --vault-name "${mlz_kv_name}" \
  --query value \
  --output tsv)

registry_password=$(az keyvault secret show \
  --name "${mlz_sp_kv_password}" \
  --vault-name "${mlz_kv_name}" \
  --query value \
  --output tsv)

# set container environment variables from MLZ config
env_vars_args=()
env_vars_args+=("KEYVAULT_ID=${mlz_kv_name}")
env_vars_args+=("TENANT_ID=${mlz_tenantid}")
env_vars_args+=("MLZ_LOCATION=${mlz_config_location}")
env_vars_args+=("SUBSCRIPTION_ID=${mlz_config_subid}")
env_vars_args+=("TF_ENV=${tf_environment}")
env_vars_args+=("MLZ_ENV=${mlz_env_name}")
env_vars_args+=("HUB_SUBSCRIPTION_ID=${mlz_saca_subid}")
env_vars_args+=("TIER0_SUBSCRIPTION_ID=${mlz_tier0_subid}")
env_vars_args+=("TIER1_SUBSCRIPTION_ID=${mlz_tier1_subid}")
env_vars_args+=("TIER2_SUBSCRIPTION_ID=${mlz_tier2_subid}")

# expand array into a string of space separated arguments
env_vars=$(printf '%s ' "${env_vars_args[*]}")

# do not quote args $env_vars, we intend to split
# ignoring shellcheck for word splitting because that is the desired behavior
# shellcheck disable=SC2086
az container create \
  --resource-group "${mlz_rg_name}" \
  --name "${mlz_instance_name}" \
  --image "${acr_login_server}/${image_name}:${image_tag}" \
  --dns-name-label "${mlz_dns_name}" \
  --environment-variables $env_vars \
  --registry-username "${registry_username}" \
  --registry-password "${registry_password}" \
  --ports 80 \
  --assign-identity \
  --only-show-errors \
  --output none

echo "INFO: granting instance ${mlz_instance_name} necessary permissions to keyvault ${mlz_kv_name}..."

container_obj_id=$(az container show \
  --resource-group "${mlz_rg_name}" \
  --name "${mlz_instance_name}" \
  --query identity.principalId \
  --output tsv)

az keyvault set-policy \
  --name "${mlz_kv_name}" \
  --key-permissions get list \
  --secret-permissions get list \
  --object-id "${container_obj_id}" \
  --only-show-errors \
  --output none

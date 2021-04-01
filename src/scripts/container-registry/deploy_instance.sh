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
  echo "create_acr.sh: Create an Azure Container Registry for hosting the MLZ UI given an MLZ configuration"
  error_log "usage: create_acr.sh <mlz config file> <image name> <image tag>"
}

if [[ "$#" -lt 3 ]]; then
   usage
   exit 1
fi

mlz_config_file=$1
image_name=$2
image_tag=$3

# generate MLZ configuration names
. "$(dirname "$(realpath "${BASH_SOURCE%/*}")")/generate_names.sh" "$mlz_config_file"

acr_login_server=$(az acr show \
  --name "${mlz_acr_name}" \
  --resource-group "${mlz_rg_name}" \
  --query "loginServer" \
  --output tsv)

echo "INFO: creating instance ${mlz_instance_name} in ${mlz_acr_name}..."

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

az container create \
  --resource-group "${mlz_rg_name}"\
  --name "${mlz_instance_name}" \
  --image "${acr_login_server}/${image_name}:${image_tag}" \
  --dns-name-label "${mlz_dns_name}" \
  --environment-variables KEYVAULT_ID="${mlz_kv_name}" TENANT_ID="${mlz_tenantid}" MLZ_LOCATION="${mlz_config_location}" SUBSCRIPTION_ID="${mlz_config_subid}" TF_ENV="${tf_environment}" MLZ_ENV="${mlz_env_name}" \
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
  --object-id "${container_obj_id}"

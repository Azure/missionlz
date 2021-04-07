#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC2154
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# create an Azure Container Registry for hosting the MLZ UI given an MLZ configuration

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "create_acr.sh: create an Azure Container Registry for hosting the MLZ UI given an MLZ configuration"
  error_log "usage: create_acr.sh <mlz config file>"
}

if [[ "$#" -lt 1 ]]; then
   usage
   exit 1
fi

mlz_config_file=$1

# generate MLZ configuration names
. "${mlz_config_file}"
. "$(dirname "$(realpath "${BASH_SOURCE%/*}")")/config/generate_names.sh" "${mlz_config_file}"

echo "INFO: creating Azure Container Registry ${mlz_acr_name}..."
az acr create \
  --resource-group "${mlz_rg_name}" \
  --name "${mlz_acr_name}" \
  --sku Basic \
  --only-show-errors \
  --output none

echo "INFO: enabling administration of registry ${mlz_acr_name}..."
sleep 60
az acr update \
  --name "${mlz_acr_name}" \
  --admin-enabled true \
  --only-show-errors \
  --output none

az acr login \
  --name "${mlz_acr_name}" \
  --only-show-errors \
  --output none

acr_id=$(az acr show \
  --name "${mlz_acr_name}" \
  --query id \
  --output tsv)

client_id=$(az keyvault secret show \
  --name "${mlz_sp_kv_name}" \
  --vault-name "${mlz_kv_name}" \
  --query value \
  --only-show-errors \
  --output tsv)

echo "INFO: granting registry identity ${client_id} 'acrpull' on ${mlz_acr_name}..."

az role assignment create \
  --assignee "${client_id}" \
  --scope "${acr_id}" \
  --role acrpull \
  --only-show-errors \
  --output none

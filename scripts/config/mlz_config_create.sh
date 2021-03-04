#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC1091,SC2154
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# Create MLZ backend config resources

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "mlz_config_create.sh: Create MLZ config resources"
  error_log "usage: mlz_config_create.sh <mlz config>"
}

if [[ "$#" -lt 3 ]]; then
   usage
   exit 1
fi

mlz_tf_cfg=$(realpath "${1}")

# Source variables
. "${mlz_tf_cfg}"

# generate MLZ configuration names
. "${BASH_SOURCE%/*}"/generate_names.sh "${mlz_tf_cfg}"

# Create Azure AD application registration and Service Principal
echo "Verifying Service Principal is unique (${mlz_sp_name})"
if [[ -z $(az ad sp list --filter "displayName eq '${mlz_sp_name}'" --query "[].displayName" -o tsv) ]];then
    echo "Service Principal does not exist...creating"
    sp_pwd=$(az ad sp create-for-rbac \
        --name "http://${mlz_sp_name}" \
        --role Contributor \
        --scopes "/subscriptions/${mlz_config_subid}" "/subscriptions/${mlz_saca_subid}" "/subscriptions/${mlz_tier0_subid}" "/subscriptions/${mlz_tier1_subid}" "/subscriptions/${mlz_tier2_subid}" \
        --query password \
        --output tsv)
else
    error_log "Service Principal named ${mlz_sp_name} already exists. This must be a unique Service Principal for your use only. Try again with a new enclave name. Exiting script."
    exit 1
fi

# Get Service Principal AppId
sp_clientid=$(az ad sp show \
    --id "http://${mlz_sp_name}" \
    --query appId \
    --output tsv)

# Get Service Principal ObjectId
sp_objid=$(az ad sp show \
    --id "http://${mlz_sp_name}" \
    --query objectId \
    --output tsv)

# Validate or create Terraform Config resource group
if [[ -z $(az group show --name "${mlz_rg_name}" --subscription "${mlz_config_subid}" --query name --output tsv) ]];then
    echo "Resource Group does not exist...creating resource group ${mlz_rg_name}"
    az group create \
        --subscription "${mlz_config_subid}" \
        --location "${mlz_config_location}" \
        --name "${mlz_rg_name}"
else
    echo "Resource Group already exists...getting resource group"
fi

# Create Key Vault
if [[ -z $(az keyvault show --name "${mlz_kv_name}" --subscription "${mlz_config_subid}" --query name --output tsv) ]];then
    echo "Key Vault ${mlz_kv_name} does not exist...creating Key Vault"
    az keyvault create \
        --name "${mlz_kv_name}" \
        --subscription "${mlz_config_subid}" \
        --resource-group "${mlz_rg_name}" \
        --location "${mlz_config_location}" \
        --output none
    echo "Key Vault ${mlz_kv_name} created!"
fi

# Create Key Vault Access Policy for Service Principal
echo "Setting Access Policy for Service Principal..."
az keyvault set-policy \
    --name "${mlz_kv_name}" \
    --subscription "${mlz_config_subid}" \
    --resource-group "${mlz_rg_name}" \
    --object-id "${sp_objid}" \
    --secret-permissions get list set \
    --output none
echo "Access Policy for Service Principal set!"

# Set Key Vault Secrets
echo "Updating KeyVault with Service Principal secrets..."
az keyvault secret set \
    --name "${mlz_sp_kv_password}" \
    --subscription "${mlz_config_subid}" \
    --vault-name "${mlz_kv_name}" \
    --value "${sp_pwd}" \
    --output none

az keyvault secret set \
    --name "${mlz_sp_kv_name}" \
    --subscription "${mlz_config_subid}" \
    --vault-name "${mlz_kv_name}" \
    --value "${sp_clientid}" \
    --output none
echo "KeyVault updated with Service Principal secrets!"

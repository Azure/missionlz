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

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "mlz_config_create.sh: Create MLZ config resources"
  error_log "usage: mlz_config_create.sh <mlz config>"
}

if [[ "$#" -lt 1 ]]; then
   usage
   exit 1
fi

mlz_tf_cfg=$(realpath "${1}")

# Source variables
. "${mlz_tf_cfg}"

# generate MLZ configuration names
. "${BASH_SOURCE%/*}/generate_names.sh" "${mlz_tf_cfg}"

# Create array of unique subscription IDs. The 'sed' command below search thru the source
# variables file looking for all lines that do not have a '#' in the line. If a line with
# a '#' is found, the '#' and ever character after it in the line is ignored. The output
# of what remains from the sed command is then piped to grep to find the words that match
# the pattern. These words are what make up the 'mlz_subs' array.
mlz_sub_pattern="mlz_.*._subid"
mlz_subs=$(< "${mlz_tf_cfg}" sed 's:#.*$::g' | grep -w "${mlz_sub_pattern}")
subs=()

for mlz_sub in $mlz_subs
do
    # Grab value of variable
    mlz_sub_id=$(echo "${mlz_sub#*=}" | tr -d '"')
    if [[ ! "${subs[*]}" =~ ${mlz_sub_id} ]];then
        subs+=("${mlz_sub_id}")
    fi
done

# Create Azure AD application registration and Service Principal
echo "Verifying Service Principal is unique (${mlz_sp_name})"
if [[ -z $(az ad sp list --filter "displayName eq '${mlz_sp_name}'" --query "[].displayName" -o tsv) ]];then
    echo "Service Principal does not exist...creating"
    sp_pwd=$(az ad sp create-for-rbac \
        --name "http://${mlz_sp_name}" \
        --skip-assignment true \
        --query password \
        --only-show-errors \
        --output tsv)

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

    # Assign Contributor role to Service Principal
    for sub in "${subs[@]}"
    do
    echo "Setting Contributor role assignment for ${mlz_sp_name} on subscription ID: ${sub}"
    az role assignment create \
        --role Contributor \
        --assignee-object-id "${sp_objid}" \
        --scope "/subscriptions/${sub}" \
        --assignee-principal-type ServicePrincipal \
        --output none
    done
else
    error_log "Service Principal named ${mlz_sp_name} already exists. This must be a unique Service Principal for your use only. Try again with a new enclave name. Exiting script."
    exit 1
fi

# Validate or create Terraform Config resource group
rg_exists="az group show \
    --name ${mlz_rg_name} \
    --subscription ${mlz_config_subid}"

if ! $rg_exists &> /dev/null; then
    echo "Resource Group does not exist...creating resource group ${mlz_rg_name}"
    az group create \
        --subscription "${mlz_config_subid}" \
        --location "${mlz_config_location}" \
        --name "${mlz_rg_name}" \
        --output none
else
    echo "Resource Group already exists...getting resource group"
fi

# Create Key Vault
kv_exists="az keyvault show \
    --name ${mlz_kv_name} \
    --subscription ${mlz_config_subid}"

if ! $kv_exists &> /dev/null; then
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

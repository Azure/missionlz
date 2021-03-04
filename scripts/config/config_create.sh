#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC1091,SC2154
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# Create Terraform module backend config resources

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "config_create.sh: Create Terraform module config resources"
  error_log "usage: config_create.sh <mlz config> <tf subscription id> <path to terraform module>"
}

if [[ "$#" -lt 3 ]]; then
   usage
   exit 1
fi

mlz_tf_cfg=$(realpath "${1}")
tf_sub_id=$2
tf_dir=$(realpath "${3}")

# source MLZ config vars
. "${mlz_tf_cfg}"

# derive TF names from the terraform directory
tf_name=$(basename "${tf_dir}")

# generate names
. "${BASH_SOURCE%/*}"/generate_names.sh "${mlz_tf_cfg}" "${tf_sub_id}" "${tf_name}"

# create TF Resource Group and Storage Account for Terraform State files
echo "Validating Resource Group for Terraform state..."
if [[ -z $(az group show --name "${tf_rg_name}" --subscription "${tf_sub_id}" --query name --output tsv) ]];then
    echo "Resource Group does not exist...creating resource group ${tf_rg_name}"
    az group create \
        --subscription "${tf_sub_id}" \
        --location "${mlz_config_location}" \
        --name "${tf_rg_name}"
else
    echo "Resource Group already exists...getting resource group"
fi

echo "Validating Storage Account for Terraform state..."
if [[ -z $(az storage account show --name "${tf_sa_name}" --subscription "${tf_sub_id}" --query name --output tsv) ]];then
    echo "Storage Account does not exist...creating storage account ${tf_sa_name}"
    az storage account create \
        --name "${tf_sa_name}" \
        --subscription "${tf_sub_id}" \
        --resource-group "${tf_rg_name}" \
        --location "${mlz_config_location}" \
        --sku Standard_LRS \
        --output none

    sa_key=$(az storage account keys list \
        --account-name "${tf_sa_name}" \
        --subscription "${tf_sub_id}" \
        --resource-group "${tf_rg_name}" \
        --query "[?keyName=='key1'].value" \
        --output tsv)

    az storage container create \
        --name "${container_name}" \
        --subscription "${tf_sub_id}" \
        --resource-group "${tf_rg_name}" \
        --account-name "${tf_sa_name}" \
        --account-key "${sa_key}" \
        --output none
    echo "Storage account and container for Terraform state created!"
else
    echo "Storage Account already exists"
fi

# generate a config.vars file
. "${BASH_SOURCE%/*}"/generate_vars.sh "${mlz_tf_cfg}" "${tf_sub_id}" "${tf_name}" "${tf_dir}"

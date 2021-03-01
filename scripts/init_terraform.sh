#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC1091,SC2143,SC2154
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC1091: Not following. Shellcheck can't follow non-constant source.
# SC2154: "var is referenced but not assigned". These values come from an external file.
# SC2143: Use grep -q instead of comparing output. Ignored for legibility.
#
# Initializes Terraform for a given directory using given a .env file for backend configuration

PGM=$(basename "${0}")

if [[ "${PGM}" == "init_terraform.sh" && "$#" -lt 1 ]]; then
   echo "${PGM}: initializes Terraform for a given directory using given a .env file for backend configuration"
   echo "usage: ${PGM} <terraform configuration directory>"
   exit 1
fi

tf_dir=$(realpath "${1}")
config_vars="${tf_dir}"/config.vars
tfvars="${tf_dir}"/"$(basename "${tf_dir}")".tfvars
plugin_dir="$(dirname "$(dirname "$(realpath "$0")")")/src/provider_cache"

# check for dependencies
. "${BASH_SOURCE%/*}"/util/checkforazcli.sh
. "${BASH_SOURCE%/*}"/util/checkforterraform.sh

# Validate necessary Azure resources exist
. "${BASH_SOURCE%/*}"/mlz_config_validate.sh "${tf_dir}"

# Get the .tfvars file matching the terraform directory name
if [[ ! -f "${tfvars}" ]]
then
    echo "${PGM}: Could not find a terraform variables file with the name '${tfvars}' at ${tf_dir}"
    echo "${PGM}: Exiting."
    exit 1
fi

# find the deployment name value in a terraform variables file, if it's not present, exit
if [[ ! $(grep -F -- "deploymentname" "${tfvars}") ]]; then
    echo "${PGM}: Could not find a variable 'deploymentname' in the .tfvars file '${tfvars}' at ${tf_dir}"
    echo "${PGM}: Please specify a deployment name in this configuration. Exiting."
    exit
fi

# Query Key Vault for Service Principal Client ID
if [[ -s "${config_vars}" ]]; then
   source "${config_vars}"
else
   echo The variable file "${config_vars}" is either empty or does not exist. Please verify file and re-run script
   exit 1
fi

if [[ -z $(az keyvault secret show --name "${sp_client_id_secret_name}" --vault-name "${mlz_cfg_kv_name}" --subscription "${mlz_cfg_sub_id}") ]]; then
   echo The Key Vault secret "${sp_client_id_secret_name}" does not exist...validate config.vars file and re-run script
   exit 1
else
   client_id=$(az keyvault secret show \
      --name "${sp_client_id_secret_name}" \
      --vault-name "${mlz_cfg_kv_name}" \
      --subscription "${mlz_cfg_sub_id}" \
      --query value \
      --output tsv)
fi

# Query Key Vault for Service Principal Password
if [[ -z $(az keyvault secret show --name "${sp_client_pwd_secret_name}" --vault-name "${mlz_cfg_kv_name}" --subscription "${mlz_cfg_sub_id}") ]]; then
   echo The Key Vault secret "${sp_client_pwd_secret_name}" does not exist...validate config.vars file and re-run script
   exit 1
else
   client_secret=$(az keyvault secret show \
      --name "${sp_client_pwd_secret_name}" \
      --vault-name "${mlz_cfg_kv_name}" \
      --subscription "${mlz_cfg_sub_id}" \
      --query value \
      --output tsv)
fi

# Validate Service Principal exists
echo Verifying Service Principal with Client ID: "${client_id}"
if [[ -z $(az ad sp list --filter "appId eq '${client_id}'") ]]; then
    echo Service Principal with Client ID "${client_id}" could not be found...validate config.vars file and re-run script
    exit 1
fi

deploymentname=$(grep -F -- "deploymentname" "${tfvars}")
key=$(echo "$deploymentname" | cut -d'"' -f 2)

# initialize terraform in the configuration directory
cd "${tf_dir}" || exit
terraform init \
   -plugin-dir="${plugin_dir}" \
   -backend-config "key=${key}" \
   -backend-config "resource_group_name=${tf_be_rg_name}" \
   -backend-config "storage_account_name=${tf_be_sa_name}" \
   -backend-config "container_name=${container_name}" \
   -backend-config "environment=${environment}" \
   -backend-config "tenant_id=${tenant_id}" \
   -backend-config "subscription_id=${sub_id}" \
   -backend-config "client_id=${client_id}" \
   -backend-config "client_secret=${client_secret}"

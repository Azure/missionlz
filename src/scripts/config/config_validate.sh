#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC1091,SC2154
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC1091: Not following. Shellcheck can't follow non-constant source.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# Validates the existence of resources required to run Terraform init and apply scripts

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "config_validate.sh : Validates the existence of resources required to run Terraform init and apply scripts"
  error_log "usage: config_validate.sh <terraform configuration directory>"
}

if [[ "$#" -lt 1 ]]; then
   usage
   exit 1
fi

tf_dir=$(realpath "${1}")
config_vars="${tf_dir}/config.vars"

# Validate resources
if [[ -s "${config_vars}" ]]; then
   source "${tf_dir}/config.vars"
else
   echo "The variable file ${config_vars} is either empty or does not exist. Please verify file and re-run script"
   exit 1
fi

# Validate Terraform Backend resource group
rg_exists="az group show \
    --name ${tf_rg_name} \
    --subscription ${mlz_config_subid}"

if ! $rg_exists &> /dev/null; then
   echo "Terraform State Resource Group '${tf_rg_name}' does not exist...validate config.vars file and re-run script"
   exit 1
fi

# Validate config key vault
kv_exists="az keyvault show \
    --name ${mlz_kv_name} \
    --subscription ${mlz_config_subid}"

if ! $kv_exists &> /dev/null; then
   echo "Key Vault to source client_id for deployment '${mlz_kv_name}' does not exist...validate config.vars file and re-run script"
   exit 1
fi

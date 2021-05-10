#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# validate cloud matches known tf_environment values

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "validate_cloud_for_tf_env.sh: validate a given tf_environment matches the user's cloud"
  error_log "usage: validate_cloud_for_tf_env.sh public"
}

this_script_path=$(realpath "${BASH_SOURCE%/*}")

# check for dependencies
"${this_script_path}/../util/checkforazcli.sh"

# inspect user input
if [[ "$#" -lt 1 ]]; then
   usage
   exit 1
fi

tf_env=$1
tf_env_lower=${tf_env,,} # ${var,,} syntax is to output a string as lowercase

current_cloud=$(az cloud show --query name --output tsv)
current_cloud_lower=${current_cloud,,} # ${var,,} syntax is to output a string as lowercase

# declare a dictionary of Terraform environment names and their clouds
# sourcing the valid combinations from here https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#environment
declare -A tfenv_cloud_pairs
tfenv_cloud_pairs['public']='azurecloud'
tfenv_cloud_pairs['usgovernment']='azureusgovernment'
tfenv_cloud_pairs['german']='azuregermancloud'
tfenv_cloud_pairs['china']='azurechinacloud'
tfenv_cloud_pairs['ussec']='ussec'
tfenv_cloud_pairs['usnat']='usnat'

tf_env_is_valid=false

# if the dictionary does contain the environment and it maps to the current cloud, then we're good
if [[ ${tfenv_cloud_pairs["${tf_env_lower}"]} == "${current_cloud_lower}" ]]; then
  tf_env_is_valid=true
fi

# otherwise, throw an error and exit
if [[ "${tf_env_is_valid}" = false ]]; then
  error_log "ERROR: Terraform environment '${tf_env}' is not a valid environment for cloud '${current_cloud}'"
  echo "INFO: check the valid settings for Terraform environment here: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#environment"
  exit 1
fi

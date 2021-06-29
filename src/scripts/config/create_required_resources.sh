#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC1091,SC2154
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC1091: Not following. Shellcheck can't follow non-constant source.
# SC2154: Referenced but not assigned. These arguments come sourced from other scripts.
#
# A script to configure a resource group that contains Terraform state and a secret store.

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "create_required_resources.sh: configure a resource group that contains Terraform state and a secret store"
  error_log "usage: create_required_resources.sh <mlz config>"
}

if [[ "$#" -lt 1 ]]; then
    usage
    exit 1
fi

mlz_config=$(realpath "${1}")

this_script_path=$(realpath "${BASH_SOURCE%/*}")

mlz_path="$(realpath "${this_script_path}/../../terraform/mlz")"

# check for dependencies
. "${this_script_path}/../util/checkforazcli.sh"

# source variables
. "${mlz_config}"

# create MLZ configuration resources
. "${this_script_path}/create_mlz_config_resources.sh" "${mlz_config}" "${mlz_env_name}" "${mlz_config_location}"

# create terraform resources given a subscription ID and terraform configuration folder
. "${this_script_path}/create_terraform_backend_resources.sh" "${mlz_config}" "${mlz_saca_subid}" "${mlz_path}"

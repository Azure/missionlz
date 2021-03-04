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

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "${0}: configure a resource group that contains Terraform state and a secret store"
  error_log "usage: ${0} <mlz tf config vars>"
}

if [[ "$#" -lt 1 ]]; then
    usage
    exit 1
fi

mlz_tf_cfg=$(realpath "${1}")

# Check for dependencies
. "${BASH_SOURCE%/*}"/util/checkforazcli.sh

# Source variables
. "${mlz_tf_cfg}"

# Core terraform modules path
core_path="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"/src/core

# Create config resources given a subscription ID and terraform configuration folder path
create_tf_config() {
    . "${BASH_SOURCE%/*}"/config/config_create.sh "${mlz_tf_cfg}" "${1}" "${2}"
}

##################################################
#
#   MLZ Deployment Setup
#
##################################################

# generate MLZ configuration resources

. "${BASH_SOURCE%/*}"/config/mlz_config_create.sh "${mlz_tf_cfg}" "${mlz_env_name}" "${mlz_config_location}"

create_tf_config "${mlz_saca_subid}" "${core_path}/saca-hub"
create_tf_config "${mlz_tier0_subid}" "${core_path}/tier-0"
create_tf_config "${mlz_tier1_subid}" "${core_path}/tier-1"
create_tf_config "${mlz_tier2_subid}" "${core_path}/tier-2"

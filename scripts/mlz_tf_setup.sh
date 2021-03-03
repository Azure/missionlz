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

PGM=$(basename "${0}")

if [[ "$#" -lt 3 ]]; then
    echo "usage: ${PGM} <mlz tf config vars> <enclave name> <location>"
    exit 1
fi

mlz_tf_cfg=$(realpath "${1}")
enclave=$2
location=$3

# Check for dependencies
. "${BASH_SOURCE%/*}"/util/checkforazcli.sh

# Source variables
. "${mlz_tf_cfg}"

##################################################
#
#   MLZ Deployment Setup
#
##################################################

# generate MLZ configuration resources
. "${BASH_SOURCE%/*}"/config/mlz_config_create.sh "${mlz_tf_cfg}" "${enclave}" "${location}"

##################################################
#
#   SACA-hub Deployment Setup
#
##################################################

saca_path="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"/src/core/saca-hub
. "${BASH_SOURCE%/*}"/config/config_create.sh "${mlz_tf_cfg}" "${enclave}" "${location}" "${mlz_saca_subid}" "${saca_path}"

##################################################
#
#   Tier-0 Deployment Setup
#
##################################################

tier0_path="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"/src/core/tier-0
. "${BASH_SOURCE%/*}"/config/config_create.sh "${mlz_tf_cfg}" "${enclave}" "${location}" "${mlz_tier0_subid}" "${tier0_path}"

##################################################
#
#   Tier-1 Deployment Setup
#
##################################################

tier1_path="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"/src/core/tier-1
. "${BASH_SOURCE%/*}"/config/config_create.sh "${mlz_tf_cfg}" "${enclave}" "${location}" "${mlz_tier1_subid}" "${tier1_path}"

##################################################
#
#   Tier-2 Deployment Setup
#
##################################################

tier2_path="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"/src/core/tier-2
. "${BASH_SOURCE%/*}"/config/config_create.sh "${mlz_tf_cfg}" "${enclave}" "${location}" "${mlz_tier2_subid}" "${tier2_path}"

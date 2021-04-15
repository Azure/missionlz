#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC2154
# SC1090: Can't follow non-constant source. These values come from an external file.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# Get the tenant ID from some MLZ configuration file and login using known Service Principal credentials

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "front_wrapper.sh: This provides a wrapper to get around python shell execution issues, it combines login and apply_tf"
  error_log "usage: front_wrapper.sh <mlz config> <globals.tfvars> <saca.tfvars> <tier0.tfvars> <tier1.tfvars> <tier2.tfvars> <display terraform output (y/n)> <sp_app_id> <sp_secret_key>"
}

if [[ "$#" -lt 6 ]]; then
   usage
   exit 1
fi

mlz_config=$1

# source the variables from MLZ config
source "${mlz_config}"

sp_id=${8:-$MLZCLIENTID}
sp_pw=${9:-$MLZCLIENTSECRET}

# login with known credentials
az cloud set -n "${mlz_cloudname}"

az login --service-principal \
  --user "${sp_id}" \
  --password="${sp_pw}" \
  --tenant "${mlz_tenantid}" \
  --allow-no-subscriptions \
  --output none

# create config resources given a subscription ID and terraform configuration folder path
src_dir=$(dirname "$(realpath "${BASH_SOURCE%/*}")")
create_tf_config() {
  . "${src_dir}/scripts/config/config_create.sh" "${mlz_config}" "${1}" "${2}"
}

# create backends for terraform modules
create_tf_config "${mlz_saca_subid}" "${src_dir}/core/saca-hub"
create_tf_config "${mlz_tier0_subid}" "${src_dir}/core/tier-0"
create_tf_config "${mlz_tier1_subid}" "${src_dir}/core/tier-1"
create_tf_config "${mlz_tier2_subid}" "${src_dir}/core/tier-2"

. "${BASH_SOURCE%/*}/apply_tf.sh" "${1}" "${2}" "${3}" "${4}" "${5}" "${6}" "${7}"
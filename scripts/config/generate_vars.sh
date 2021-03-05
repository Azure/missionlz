#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC1091,SC2154
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# Generate a config.vars file at a given Terraform directory

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "generate_vars.sh: Generate a config.vars file at a given Terraform directory"
  error_log "usage: generate_vars.sh <mlz config> <tf sub id> <tf name> <tf dir>"
}

if [[ "$#" -lt 4 ]]; then
   usage
   exit 1
fi

mlz_tf_cfg=$1
tf_sub_id=${2}
tf_name=${3}
tf_dir=$(realpath "${4}")

# generate names
. "${BASH_SOURCE%/*}/generate_names.sh" "${mlz_tf_cfg}" "${tf_sub_id}" "${tf_name}"

# generate a config.vars file
config_vars="${tf_dir}/config.vars"
rm -f "$config_vars"
touch "$config_vars"
{
    echo "tenant_id=${mlz_tenantid}"
    echo "mlz_env_name=${mlz_env_name}"
    echo "mlz_cfg_sub_id=${mlz_config_subid}"
    echo "mlz_cfg_kv_name=${mlz_kv_name}"
    echo "sub_id=${tf_sub_id}"
    echo "location=${mlz_config_location}"
    echo "tf_be_rg_name=${tf_rg_name}"
    echo "tf_be_sa_name=${tf_sa_name}"
    echo "sp_client_id_secret_name=${mlz_sp_kv_name}"
    echo "sp_client_pwd_secret_name=${mlz_sp_kv_password}"
    echo "environment=${tf_environment}"
    echo "container_name=${container_name}"
} >> "$config_vars"

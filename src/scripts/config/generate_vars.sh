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
  error_log "usage: generate_vars.sh <mlz config> <tf sub id> <tf dir>"
}

if [[ "$#" -lt 3 ]]; then
   usage
   exit 1
fi

mlz_config=$(realpath "${1}")
tf_sub_id="${2}"
tf_dir=$(realpath "${3}")
tf_name=$(basename "${tf_dir}")

# source mlz config
. "${mlz_config}"

# generate names
. "${BASH_SOURCE%/*}/generate_names.sh" "${mlz_config}" "${tf_name}"

# generate a config.vars file
config_vars="${tf_dir}/config.vars"
rm -f "$config_vars"
touch "$config_vars"
{
    echo "metadata_host=${mlz_metadatahost}"
    echo "tenant_id=${mlz_tenantid}"
    echo "mlz_env_name=${mlz_env_name}"
    echo "mlz_config_subid=${mlz_config_subid}"
    echo "mlz_kv_name=${mlz_kv_name}"
    echo "sub_id=${tf_sub_id}"
    echo "location=${mlz_config_location}"
    echo "tf_rg_name=${tf_rg_name}"
    echo "tf_sa_name=${tf_sa_name}"
    echo "mlz_kv_sp_client_id=${mlz_kv_sp_client_id}"
    echo "mlz_kv_sp_client_secret=${mlz_kv_sp_client_secret}"
    echo "mlz_kv_sp_object_id=${mlz_kv_sp_object_id}"
    echo "environment=${tf_environment}"
    echo "container_name=${container_name}"
} >> "$config_vars"

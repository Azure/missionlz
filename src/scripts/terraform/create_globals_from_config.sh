#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=1090,2154
# SC1090: Can't follow non-constant source. This file is input.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# generate a terraform globals tfvars file given an MLZ config and a desired tfvars file name

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "create_globals_from_config.sh: generate a terraform tfvars file given an MLZ config and a desired tfvars file name"
  echo "create_globals_from_config.sh: <destination file path> <mlz config file path>"
  show_help
}

if [[ "$#" -lt 2 ]]; then
   usage
   exit 1
fi

file_to_create=$1
mlz_config=$2

# source config
. "${mlz_config}"

# given a key and value write a key="value" new line to a file
append_kvp() {
  key=$1
  value=$2
  printf "%s=\"%s\"\n" "${key}" "${value}" >> "${file_to_create}"
}

# write the file to the desired path
rm -f "$file_to_create"
dest_file_dir=$(dirname "${file_to_create}")
mkdir -p "${dest_file_dir}"
touch "$file_to_create"

append_kvp "deploymentname" "${mlz_env_name}"

append_kvp "tf_environment" "${tf_environment}"

append_kvp "mlz_cloud" "${mlz_cloudname}"
append_kvp "mlz_tenantid" "${mlz_tenantid}"
append_kvp "mlz_location" "${mlz_config_location}"
append_kvp "mlz_metadatahost" "${mlz_metadatahost}"

append_kvp "tier0_subid" "${mlz_tier0_subid}"
append_kvp "tier0_rgname" "rg-t0-${mlz_env_name}"
append_kvp "tier0_vnetname" "vn-t0-${mlz_env_name}"

append_kvp "tier1_subid" "${mlz_tier1_subid}"
append_kvp "tier1_rgname" "rg-t1-${mlz_env_name}"
append_kvp "tier1_vnetname" "vn-t1-${mlz_env_name}"

append_kvp "tier2_subid" "${mlz_tier2_subid}"
append_kvp "tier2_rgname" "rg-t2-${mlz_env_name}"
append_kvp "tier2_vnetname" "vn-t2-${mlz_env_name}"

append_kvp "saca_subid" "${mlz_saca_subid}"
append_kvp "saca_rgname" "rg-saca-${mlz_env_name}"
append_kvp "saca_vnetname" "vn-saca-${mlz_env_name}"
append_kvp "saca_fwname" "Firewall${mlz_env_name}"
append_kvp "saca_lawsname" "laws-${mlz_env_name}"

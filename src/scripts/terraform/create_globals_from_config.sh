#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
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

# write the file to the desired path
rm -f "$file_to_create"
dest_file_dir=$(dirname ${file_to_create})
mkdir -p "${dest_file_dir}"
touch "$file_to_create"
{
  echo "tf_environment=${tf_environment}"
  echo "mlz_cloud=${mlz_cloudname}"
  echo "mlz_tenantid=${mlz_tenantid}"
  echo "mlz_location=${mlz_config_location}"
  echo "mlz_metadatahost=${mlz_metadatahost}"
  echo "tier0_subid=${mlz_tier0_subid}"
  echo "tier0_rgname=rg-t0-${mlz_env_name}"
  echo "tier0_vnetname=vn-t0-${mlz_env_name}"
  echo "tier1_subid=${mlz_tier1_subid}"
  echo "tier1_rgname=rg-t1-${mlz_env_name}"
  echo "tier1_vnetname=vn-t1-${mlz_env_name}"
  echo "tier2_subid=${mlz_tier2_subid}"
  echo "tier2_rgname=rg-t2-${mlz_env_name}"
  echo "tier2_vnetname=vn-t2-${mlz_env_name}"
  echo "saca_subid=${mlz_saca_subid}"
  echo "saca_rgname=rg-saca-${mlz_env_name}"
  echo "saca_vnetname=vn-saca-${mlz_env_name}"
  echo "saca_fwname=Firewall${mlz_env_name}"
  echo "saca_lawsname=laws-${mlz_env_name}"
} >> "$file_to_create"


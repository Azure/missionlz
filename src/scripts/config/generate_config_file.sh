#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Generate a file named mlz.config given MLZ prerequisites.

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "generate_config_file.sh: Generate a file at the root named mlz.config given MLZ prerequisites"
  error_log "usage: generate_config_file.sh <terraform environment> <metadata host> <environment name> <location> <config subscription id> <tenant id> <saca subscription id> <tier 0 subscription id> <tier 1 subscription id> <tier 2 subscription id>"
}

if [[ "$#" -lt 11 ]]; then
   usage
   exit 1
fi

dest_file=${1}
tf_env=${2}
metadatahost=${3}
env_name=${4}
location=${5}
config_subid=${6}
tenantid=${7}
saca_subid=${8}
tier0_subid=${9}
tier1_subid=${10}
tier2_subid=${11}

rm -f "$dest_file"
touch "$dest_file"
{
    echo "tf_environment=${tf_env}"
    echo "mlz_metadatahost=${metadatahost}"
    echo "mlz_env_name=${env_name}"
    echo "mlz_config_location=${location}"
    echo "mlz_config_subid=${config_subid}"
    echo "mlz_tenantid=${tenantid}"
    echo "mlz_saca_subid=${saca_subid}"
    echo "mlz_tier0_subid=${tier0_subid}"
    echo "mlz_tier1_subid=${tier1_subid}"
    echo "mlz_tier2_subid=${tier2_subid}"
} >> "$dest_file"

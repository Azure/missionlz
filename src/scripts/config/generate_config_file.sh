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
  error_log "usage: generate_config_file.sh <terraform environment> <metadata host> <environment name> <location> <config subscription id> <tenant id>"
}

if [[ "$#" -lt 7 ]]; then
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

rm -f "$dest_file"
touch "$dest_file"
{
    echo "tf_environment=${tf_env}"
    echo "mlz_metadatahost=${metadatahost}"
    echo "mlz_env_name=${env_name}"
    echo "mlz_config_location=${location}"
    echo "mlz_config_subid=${config_subid}"
    echo "mlz_tenantid=${tenantid}"
} >> "$dest_file"

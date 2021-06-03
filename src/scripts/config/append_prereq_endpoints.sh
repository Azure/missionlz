#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# append pre-req endpoints to an MLZ config file

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "append_prereq_endpoints.sh: append pre-req endpoints to an MLZ config file"
  error_log "usage: append_prereq_endpoints.sh <file to append>"
}

if [[ "$#" -lt 1 ]]; then
   usage
   exit 1
fi

file_to_append=$1

# create a dictionary of mlz_* values we want from an `az cloud show` result
declare -A mlz_az_cloud_keys
mlz_az_cloud_keys['mlz_metadatahost']='endpoints.resourceManager'
mlz_az_cloud_keys['mlz_acrLoginServerEndpoint']='suffixes.acrLoginServerEndpoint'
mlz_az_cloud_keys['mlz_keyvaultDns']='suffixes.keyvaultDns'
mlz_az_cloud_keys['mlz_cloudname']='name'
mlz_az_cloud_keys['mlz_activeDirectory']='endpoints.activeDirectory'

# since we cannot guarantee the results of `az cloud show` for each value we want,
# we query for them individually when printing to the file to accommodate for empty results
append_cloud_value() {
  local mlz_key_name=$1
  local cloud_key_name=$2
  local file=$3

  local cloud_key_value
  cloud_key_value=$(az cloud show --query "${cloud_key_name}" --output tsv)

  if [[ $cloud_key_value ]]; then
    printf "%s=%s\n" "${mlz_key_name}" "${cloud_key_value}" >> "${file}"
  fi
}

# for each member of the dictionary, write "key=$(az cloud show...)" to a file
for mlz_key_name in "${!mlz_az_cloud_keys[@]}"; do
    append_cloud_value "$mlz_key_name" "${mlz_az_cloud_keys[$mlz_key_name]}" "${file_to_append}"
done

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

cloudEndpoints=($(az cloud show \
  --query '[endpoints.resourceManager, suffixes.acrLoginServerEndpoint, suffixes.keyvaultDns]' \
  --output tsv))

resourceManager=${cloudEndpoints[0]}
acrLoginServerEndpoint=${cloudEndpoints[1]}
keyvaultDns=${cloudEndpoints[2]}

append_if_not_empty() {
  key_name=$1
  key_value=$2
  file=$3
  if [[ $key_value ]]; then
    printf "${key_name}=${key_value}\n" >> "${file}"
  fi
}

append_if_not_empty "metadatahost" ${cloudEndpoints[0]} ${file_to_append}
append_if_not_empty "acrLoginServerEndpoint" ${cloudEndpoints[1]} ${file_to_append}
append_if_not_empty "keyvaultDns" ${cloudEndpoints[2]} ${file_to_append}

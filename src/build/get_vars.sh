#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Get MLZ Configuration and Terraform Variables from a storage account

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "get_vars.sh: login using known Service Principal credentials into a given tenant"
  error_log "usage: get_vars.sh.sh <storage account name> <storage account token> <storage account container>"
}

if [[ "$#" -lt 3 ]]; then
   usage
   exit 1
fi

sa_name=$1
sa_token=$2
sa_container=$3

# create some place to hold the configuration and TF vars
rm -rf "vars"
mkdir "vars"

# download everything in the container to that place
az storage blob download-batch \
  --account-name "${sa_name}" \
  --sas-token "${sa_token}" \
  --source "${sa_container}" \
  --pattern "*" \
  --destination "vars" \
  --output "none" \
  --only-show-errors

# remove Windows EOL characters
for file in vars/*; do
  sed -i 's/\r$//' "${file}"
done

#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# validate that a given location is present in a user's cloud

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "validateazlocation.sh: validate that a given location is present in a user's cloud"
  error_log "usage: validateazlocation.sh eastus"
}

this_script_path=$(realpath "${BASH_SOURCE%/*}")

# check for dependencies
"${this_script_path}/checkforazcli.sh"

# inspect user input
if [[ "$#" -lt 1 ]]; then
   usage
   exit 1
fi

location=$1

current_cloud=$(az cloud show --query name --output tsv)
current_sub=$(az account show --query id --output tsv)
valid_locations=$(az account list-locations --query [].name --output tsv)

# if the active subscription does not support the given location, throw an error and exit
if ! echo "$valid_locations" | grep -iwq "${location}"; then
  error_log "ERROR: could not find region '${location}' for subscription of '${current_sub}' in current cloud '${current_cloud}' "
  echo "INFO: is this a valid region? Try 'az account list-locations' to see what regions are available to you."
  echo "INFO: do you have the correct cloud set? Try 'az cloud set' to set it."
  exit 1
fi

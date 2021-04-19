#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1083,SC1090,SC1091,2154
# SC1083: This is literal.
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC1091: Not following. Shellcheck can't follow non-constant source.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# This script will apply and publish a local blueprint as well as apply it to the target subscription

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "apply_blueprint.sh: Deploy a locally stored blueprint to a subscription"
  error_log "usage: apply_blueprint.sh <subscription> <location> <blueprint_name>"
}

if [[ "$#" -lt 2 ]]; then
    usage
    exit 1
fi

subscription_id=$1
location=$2
blueprint_name=$3

timestamp=$(date +%s)

# Blueprint requires an extension, lets set it to install that
az config set extension.use_dynamic_install=yes_without_prompt

# For execution we need some locations
blueprints=$(realpath ../policy/blueprints/)
scripts_path=$(realpath ../)

thisblueprint="${blueprints}/${blueprint_name}"
blueprint_parameters="${blueprints}/parameters/${blueprint_name}.json"

# Validate template exists
. "${scripts_path}/util/checkforfile.sh" \
   "${thisblueprint}" \
   "The blueprint definition name could not be found, please check spelling and that you have copied the template to the src/scripts/policy/blueprints directory"


# Import the template to the subscription
az blueprint import --name "${blueprint_name}" --input-path "${thisblueprint}" --subscription "${subscription_id}" -y

# Publish the imported blueprint
blueprint_version=$(az blueprint publish --blueprint-name "${blueprint_name}" --version "${timestamp}" --query id --output tsv)

# Assign the blueprint to the environment
az blueprint assignment create --name "${blueprint_name}" --blueprint-version "${blueprint_version}" --subscription "${subscription_id}" --location "${location}" --parameters "${blueprint_parameters}"

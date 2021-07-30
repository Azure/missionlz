#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090
# SC1090: Can't follow non-constant source. Use a directive to specify location.
#
# validates that a Service Principal has 'Contributor' or 'Owner'
# role assigned for the subscriptions in a given .mlzconfig

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  error_log "usage: validate_minimum_role_for_sp.sh <mlz config> <client ID>"
  echo "validate_minimum_role_for_sp.sh: validates that a Service Principal for a given Client ID has 'Contributor' or 'Owner' role assigned for the subscriptions in a given .mlzconfig"
}

if [[ "$#" -lt 2 ]]; then
   usage
   exit 1
fi

mlz_config=$(realpath "${1}")
client_id=${2}

# Source variables
. "${mlz_config}"

# Create array of unique subscription IDs. The 'sed' command below search thru the source
# variables file looking for all lines that do not have a '#' in the line. If a line with
# a '#' is found, the '#' and ever character after it in the line is ignored. The output
# of what remains from the sed command is then piped to grep to find the words that match
# the pattern. These words are what make up the 'mlz_subs' array.
mlz_sub_pattern="mlz_.*._subid"
mlz_subs=$(< "${mlz_config}" sed 's:#.*$::g' | grep -w "${mlz_sub_pattern}")
subs=()
for mlz_sub in $mlz_subs
do
    mlz_sub_id=$(echo "${mlz_sub#*=}" | tr -d '"')
    if [[ ! "${subs[*]}" =~ ${mlz_sub_id} ]];then
        subs+=("${mlz_sub_id}")
    fi
done

object_id=$(az ad sp list \
    --filter "appId eq '${client_id}'" \
    --query "[].objectId" \
    --output tsv)

subs_requiring_role_assignment=()

for sub in "${subs[@]}"
do
    valid_assignments=$(az role assignment list \
        --assignee "${object_id}" \
        --scope "/subscriptions/${sub}" \
        --query "[?roleDefinitionName=='Contributor' || roleDefinitionName=='Owner'].{scope: scope}" \
        --output tsv)
    if [[ -z $valid_assignments ]]; then
        subs_requiring_role_assignment+=("${sub}")
    fi
done

if [[ ${#subs_requiring_role_assignment[@]} -gt 0 ]]; then
    error_log "ERROR: service principal with client ID ${client_id} is missing 'Contributor' role!"
    echo "INFO: at minimum, the 'Contributor' role is required to manage resources via Terraform."
    echo "INFO: to set this role for the relevant subscriptions, a user with the 'Owner' role can try these commands:"

    for sub in "${subs_requiring_role_assignment[@]}"
    do
        echo "INFO: az role assignment create --assignee-object-id ${object_id} --role \"Contributor\" --scope \"/subscriptions/${sub}\""
    done

    error_log "ERROR: please assign the 'Contributor' role to this service principal and try again."
    exit 1
fi

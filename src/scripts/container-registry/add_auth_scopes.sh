#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,2154
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# create an app registration and add MSAL auth scopes to facilitate user logon to MLZ UI

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "add_auth_scopes.sh: create an app registration and add MSAL auth scopes to facilitate user logon to MLZ UI"
  error_log "usage: add_auth_scopes.sh <mlz config file> <mlz UI FQDN url>"
}

if [[ "$#" -lt 2 ]]; then
   usage
   exit 1
fi

mlz_config_file=$1
fqdn=$2

# generate MLZ configuration names
. "${mlz_config_file}"
. "$(dirname "$(realpath "${BASH_SOURCE%/*}")")/config/generate_names.sh" "${mlz_config_file}"

# path to app resources definition file
required_resources_json_file="$(dirname "$(realpath "${BASH_SOURCE%/*}")")/config/mlz_login_app_resources.json"

# generate app registration
echo "INFO: creating app registration ${mlz_fe_app_name} to facilitate user logon at ${fqdn}..."
app_id=$(az ad app create \
  --display-name "${mlz_fe_app_name}" \
  --reply-urls "http://${fqdn}/redirect" \
  --required-resource-accesses "${required_resources_json_file}" \
  --only-show-errors \
  --query appId \
  --output tsv)

# accomodate for transient behavior where App Registration is created
# but an immediate query for it will fail
# and attempt for max_wait_in_seconds before giving up.
wait_for_app_creation() {
    app_id_to_query=$1
    app_query="az ad app show --id ${app_id_to_query}"

    sleep_time_in_seconds=10
    max_wait_in_seconds=180
    max_retries=$((max_wait_in_seconds/sleep_time_in_seconds))

    count=1

    while ! $app_query &> /dev/null
    do
        echo "INFO: waiting for app registration for ${app_id_to_query} to come back from query '${app_query}' (${count}/${max_retries})..."
        echo "INFO: trying again in ${sleep_time_in_seconds} seconds..."
        sleep "${sleep_time_in_seconds}"

        if [[ ${count} -eq max_retries ]]; then
            error_log "ERROR: unable to retrieve the app registration for ${app_id_to_query} from query '${app_query}' in ${max_wait_in_seconds} seconds. Investigate and re-run script."
            exit 1
        fi

        count=$((count +1))
    done
}

# accomodate for transient behavior where App Registration is created
# but an immediate query for its properties will fail
# and attempt for max_wait_in_seconds before giving up.
wait_for_app_query_from_list() {
    app_name_to_query=$1
    property_to_query=$2

    property_query="az ad app list --display-name ${app_name_to_query} --query [].${property_to_query} --output tsv"

    sleep_time_in_seconds=10
    max_wait_in_seconds=180
    max_retries=$((max_wait_in_seconds/sleep_time_in_seconds))

    count=1

    while [[ -z $($property_query)  ]]
    do
      echo "INFO: waiting for query \"${property_query}\" to return results (${count}/${max_retries})"
      echo "INFO: trying again in ${sleep_time_in_seconds} seconds..."
      sleep "${sleep_time_in_seconds}"

      if [[ ${count} -eq max_retries ]]; then
          error_log "ERROR: unable to get results from query \"${property_query}\" in ${max_wait_in_seconds} seconds. Investigate and re-run script."
          exit 1
      fi

      count=$((count +1))
    done
}

wait_for_app_creation "${app_id}"
wait_for_app_query_from_list "${mlz_fe_app_name}" "appId"

echo "INFO: sourcing app registration information for app ID ${app_id}..."
client_password=$(az ad app credential reset \
    --id "${app_id}" \
    --query password \
    --only-show-errors \
    --output tsv)

# update keyvault with the app registration information
echo "INFO: storing app registration information for app ID ${app_id} in ${mlz_kv_name}..."
az keyvault secret set \
  --name "${mlz_login_app_kv_name}" \
  --subscription "${mlz_config_subid}" \
  --vault-name "${mlz_kv_name}" \
  --value "${app_id}" \
  --only-show-errors \
  --output none

az keyvault secret set \
  --name "${mlz_login_app_kv_password}" \
  --subscription "${mlz_config_subid}" \
  --vault-name "${mlz_kv_name}" \
  --value "${client_password}" \
  --only-show-errors \
  --output none

echo "INFO: waiting thirty seconds to allow for app registration propogation..."
sleep 30

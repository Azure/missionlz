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
az ad app create \
  --display-name "${mlz_fe_app_name}" \
  --reply-urls "http://${fqdn}/redirect" \
  --required-resource-accesses "${required_resources_json_file}" \
  --only-show-errors \
  --output none

# wait_for_query_success will attempt the query passed by argument
# if the query does not return a result within max_wait_in_seconds it will exit.
wait_for_query_success() {
  query=$1

  sleep_time_in_seconds=10
  max_wait_in_seconds=180
  max_retries=$((max_wait_in_seconds/sleep_time_in_seconds))

  count=1

  while [[ -z $($query)  ]]
  do
      echo "INFO: waiting for query \"${query}\" to return results (${count}/${max_retries})"
      echo "INFO: trying again in ${sleep_time_in_seconds} seconds..."
      sleep "${sleep_time_in_seconds}"

      if [[ ${count} -eq max_retries ]]; then
          error_log "ERROR: unable to get results from query \"${query}\" in ${max_wait_in_seconds} seconds. Investigate and re-run script."
          exit 1
      fi

      count=$((count +1))
  done
}

# use `wait_for_query_success` to accomodate transient failures where
# app creation completes but an immediate query for it will fail
app_id_query="az ad app list --display-name ${mlz_fe_app_name} --query [].appId --output tsv"
wait_for_query_success "$app_id_query"

client_id=$($app_id_query)

client_password=$(az ad app credential reset \
    --id ${client_id} \
    --query password \
    --only-show-errors \
    --output tsv)

# update keyvault with the app registration information
echo "INFO: storing app registration information for client ID ${client_id} in ${mlz_kv_name}..."
az keyvault secret set \
  --name "${mlz_login_app_kv_name}" \
  --subscription "${mlz_config_subid}" \
  --vault-name "${mlz_kv_name}" \
  --value "${client_id}" \
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

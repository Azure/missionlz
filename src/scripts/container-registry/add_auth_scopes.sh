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

app_exists () {

    app_name=$1
    app_property=$2

    echo "App name in app check function = ${1}"
    echo "App ID in app check function = ${2}"

    app_query="az ad app list \
        --display-name ${app_name} \
        --query [].${app_property} \
        --output tsv"
    
    sleep 30

    if ! $app_query &> /dev/null; then

        sleep_time_in_seconds=10
        max_wait_in_minutes=3
        max_wait_in_seconds=180
        max_retries=$((max_wait_in_seconds/sleep_time_in_seconds))

        echo "INFO: maximum time to wait in seconds = ${max_wait_in_seconds}"
        echo "INFO: maximum number of retries = ${max_retries}"

        count=1

        while ! $app_query &> /dev/null
        do

            echo "INFO: waiting for service principal ${sp_name} to populate property ${sp_property} (${count}/${max_retries})"
            echo "INFO: trying again in ${sleep_time_in_seconds} seconds..."
            sleep "${sleep_time_in_seconds}"

            if [[ ${count} -eq max_retries ]]; then
                error_log "ERROR: unable to determine ${app_property} for the service principal ${app_property} in ${max_wait_in_minutes} minutes. Investigate and re-run script."
                exit 1
            fi

            count=$((count +1))

        done
    fi

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
if [[ -z $(az ad app list --filter "displayName eq '${mlz_fe_app_name}'" --query "[].displayName" -o tsv) ]];then
    echo "INFO: creating app registration ${mlz_fe_app_name} to facilitate user logon at ${fqdn}..."
    client_id=$(az ad app create \
        --display-name "${mlz_fe_app_name}" \
        --reply-urls "http://${fqdn}/redirect" \
        --required-resource-accesses "${required_resources_json_file}" \
        --query appId \
        --only-show-errors \
        --output tsv)
    
    echo "App ID after app creation = ${client_id}"

    # Get App Registration AppId
    # Added the sleep below to accomodate for the transient behavior where the Application Registration creation
    # is complete but an immediate query for it will fail. The sleep loop will run for 3 minutes and then
    # the script will exit due to a platform problem
    app_exists "${mlz_fe_app_name}" "appId"

    client_password=$(az ad app credential reset \
        --id ${client_id} \
        --query password \
        --only-show-errors \
        --output tsv)
fi

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

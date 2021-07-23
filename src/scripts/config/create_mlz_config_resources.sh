#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC1091,SC2154,SC2207
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# Create MLZ backend config resources

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "create_mlz_config_resources.sh: Create MLZ config resources"
  error_log "usage: create_mlz_config_resources.sh <mlz config> <create service principal (true or false)>"
}

if [[ "$#" -lt 1 ]]; then
   usage
   exit 1
fi

mlz_config=$(realpath "${1}")
create_service_principal=${2:-true}

this_script_path=$(realpath "${BASH_SOURCE%/*}")

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

# generate MLZ configuration names
. "${BASH_SOURCE%/*}/generate_names.sh" "${mlz_config}"

echo "INFO: creating MLZ resources for ${mlz_env_name}..."

for mlz_sub in $mlz_subs
do
    # Grab value of variable
    mlz_sub_id=$(echo "${mlz_sub#*=}" | tr -d '"')
    if [[ ! "${subs[*]}" =~ ${mlz_sub_id} ]];then
        subs+=("${mlz_sub_id}")
    fi
done

# accomodate for transient behavior where Service Principal is created
# but an immediate query for it will fail
# and attempt for max_wait_in_seconds before giving up.
wait_for_sp_creation() {
    sp_name=$1
    sp_query="az ad sp show --id ${sp_name}"

    sleep_time_in_seconds=10
    max_wait_in_seconds=180
    max_retries=$((max_wait_in_seconds/sleep_time_in_seconds))

    count=1

    while ! $sp_query &> /dev/null
    do
        echo "INFO: waiting for service principal ${sp_name} to come back from query '${sp_query}' (${count}/${max_retries})..."
        echo "INFO: trying again in ${sleep_time_in_seconds} seconds..."
        sleep "${sleep_time_in_seconds}"

        if [[ ${count} -eq max_retries ]]; then
            error_log "ERROR: unable to retrieve the service principal ${sp_name} from query '${sp_query}' in ${max_wait_in_seconds} seconds. Investigate and re-run script."
            exit 1
        fi

        count=$((count +1))
    done
}

# accomodate for transient behavior where Service Principal is created
# but an immediate query for its properties will fail
# and attempt for max_wait_in_seconds before giving up.
wait_for_sp_property() {
    sp_name=$1
    sp_property=$2

    args=(--filter "\"appId eq '$sp_name'\"" --query "[0].$sp_property" --output tsv)
    query="az ad sp list ${args[*]}"

    sleep_time_in_seconds=10
    max_wait_in_seconds=180
    max_retries=$((max_wait_in_seconds/sleep_time_in_seconds))

    count=1

    while [[ -z $(eval "$query") ]]
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

check_for_arm_credential() {
    util_path=$(realpath "${this_script_path}/../util")
    "${util_path}/checkforarmcredential.sh" "ERROR: When using a user-provided service principal, these environment variables are mandatory: ARM_CLIENT_ID, ARM_CLIENT_SECRET"
}

validate_minimum_role_for_sp() {
    "${this_script_path}/validate_minimum_role_for_sp.sh" "${mlz_config}" "${ARM_CLIENT_ID}"
}

# Create Service Principal
if [[ "${create_service_principal}" == false ]];
then
    check_for_arm_credential
    validate_minimum_role_for_sp

    echo "INFO: using user-supplied service principal with client ID ${ARM_CLIENT_ID}..."

    sp_client_id="${ARM_CLIENT_ID}"
    sp_client_secret="${ARM_CLIENT_SECRET}"
    sp_object_id=$(az ad sp list \
        --filter "appId eq '${ARM_CLIENT_ID}'" \
        --query "[].objectId" \
        --output tsv)
else
    echo "INFO: verifying service principal ${mlz_sp_name} is unique..."
    if [[ -z $(az ad sp list \
               --filter "displayName eq 'http://${mlz_sp_name}'" \
               --query "[].displayName" \
               --output tsv) ]];
    then
        echo "INFO: creating service principal ${mlz_sp_name}..."
        sp_creds=($(az ad sp create-for-rbac \
            --name "http://${mlz_sp_name}" \
            --skip-assignment true \
            --query "[password, appId]" \
            --only-show-errors \
            --output tsv))

        sp_client_secret=${sp_creds[0]}
        sp_client_id=${sp_creds[1]}

        wait_for_sp_creation "${sp_client_id}"
        wait_for_sp_property "${sp_client_id}" "objectId"

        odata_filter_args=(--filter "\"appId eq '$sp_client_id'\"" --query "[0].objectId" --output tsv)
        object_id_query="az ad sp list ${odata_filter_args[*]}"

        sp_object_id=$(eval "$object_id_query")

        # Assign Contributor Role to Subscriptions
        for sub in "${subs[@]}"
        do
            echo "INFO: setting Contributor role assignment for ${sp_client_id} on subscription ${sub}..."
            az role assignment create \
                --role Contributor \
                --assignee-object-id "${sp_object_id}" \
                --scope "/subscriptions/${sub}" \
                --assignee-principal-type ServicePrincipal \
                --output none
        done
    else
        error_log "ERROR: A service principal named ${mlz_sp_name} already exists. This must be a unique service principal for your use only. Try again with a new mlz-env-name. Exiting script."
        exit 1
    fi
fi

# Validate or create Terraform Config resource group
rg_exists="az group show \
    --name ${mlz_rg_name} \
    --subscription ${mlz_config_subid}"

echo "INFO: sourcing resource group ${mlz_rg_name} for MLZ resources..."
if ! $rg_exists &> /dev/null; then
    echo "INFO: creating resource group ${mlz_rg_name} for MLZ resources..."
    az group create \
        --subscription "${mlz_config_subid}" \
        --location "${mlz_config_location}" \
        --name "${mlz_rg_name}" \
        --tags "DeploymentName=${mlz_config_tag}" \
        --output none
fi

# Create Key Vault
kv_exists="az keyvault show \
    --name ${mlz_kv_name} \
    --subscription ${mlz_config_subid}"

echo "INFO: sourcing keyvault ${mlz_kv_name} for MLZ resources..."
if ! $kv_exists &> /dev/null; then
    echo "INFO: creating keyvault ${mlz_kv_name} for MLZ resources..."
    az keyvault create \
        --name "${mlz_kv_name}" \
        --subscription "${mlz_config_subid}" \
        --resource-group "${mlz_rg_name}" \
        --location "${mlz_config_location}" \
        --output none
fi

# Create Key Vault Access Policy for Service Principal
echo "INFO: setting access policy on ${mlz_kv_name} for service principal ${mlz_sp_name}..."
az keyvault set-policy \
    --name "${mlz_kv_name}" \
    --subscription "${mlz_config_subid}" \
    --resource-group "${mlz_rg_name}" \
    --object-id "${sp_object_id}" \
    --secret-permissions get list set \
    --output none

# Set Key Vault Secrets
echo "INFO: setting secrets in ${mlz_kv_name} for service principal ${mlz_sp_name}..."
az keyvault secret set \
    --name "${mlz_kv_sp_client_secret}" \
    --subscription "${mlz_config_subid}" \
    --vault-name "${mlz_kv_name}" \
    --value "${sp_client_secret}" \
    --output none

az keyvault secret set \
    --name "${mlz_kv_sp_client_id}" \
    --subscription "${mlz_config_subid}" \
    --vault-name "${mlz_kv_name}" \
    --value "${sp_client_id}" \
    --output none

az keyvault secret set \
    --name "${mlz_kv_sp_object_id}" \
    --subscription "${mlz_config_subid}" \
    --vault-name "${mlz_kv_name}" \
    --value "${sp_object_id}" \
    --output none

echo "INFO: MLZ resources for ${mlz_env_name} created!"

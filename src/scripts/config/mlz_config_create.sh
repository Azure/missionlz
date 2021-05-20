#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC1091,SC2154
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# Create MLZ backend config resources

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "mlz_config_create.sh: Create MLZ config resources"
  error_log "usage: mlz_config_create.sh <mlz config>"
}

if [[ "$#" -lt 1 ]]; then
   usage
   exit 1
fi

mlz_config=$(realpath "${1}")

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

    query="az ad sp show --id ${sp_name} --query ${sp_property} --output tsv"

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

# Create Azure AD application registration and Service Principal
# TODO: Lift the subscription scoping out of here and move into conditional
echo "INFO: verifying service principal ${mlz_sp_name} is unique..."
if [[ -z $(az ad sp list --filter "displayName eq '${mlz_sp_name}'" --query "[].displayName" -o tsv) ]];then
    echo "INFO: creating service principal ${mlz_sp_name}..."
    sp_pwd=$(az ad sp create-for-rbac \
        --name "http://${mlz_sp_name}" \
        --skip-assignment true \
        --query password \
        --only-show-errors \
        --output tsv)

    wait_for_sp_creation "http://${mlz_sp_name}"
    wait_for_sp_property "http://${mlz_sp_name}" "appId"
    wait_for_sp_property "http://${mlz_sp_name}" "objectId"

    sp_clientid=$(az ad sp show \
        --id "http://${mlz_sp_name}" \
        --query appId \
        --output tsv)

    sp_objid=$(az ad sp show \
        --id "http://${mlz_sp_name}" \
        --query objectId \
        --output tsv)

    # Assign Contributor role to Service Principal
    for sub in "${subs[@]}"
    do
    echo "INFO: setting Contributor role assignment for ${mlz_sp_name} on subscription ${sub}..."
    az role assignment create \
        --role Contributor \
        --assignee-object-id "${sp_objid}" \
        --scope "/subscriptions/${sub}" \
        --assignee-principal-type ServicePrincipal \
        --output none
    done
else
    error_log "ERROR: A service principal named ${mlz_sp_name} already exists. This must be a unique service principal for your use only. Try again with a new mlz-env-name. Exiting script."
    exit 1
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
    --object-id "${sp_objid}" \
    --secret-permissions get list set \
    --output none

# Set Key Vault Secrets
echo "INFO: setting secrets in ${mlz_kv_name} for service principal ${mlz_sp_name}..."
az keyvault secret set \
    --name "${mlz_sp_kv_password}" \
    --subscription "${mlz_config_subid}" \
    --vault-name "${mlz_kv_name}" \
    --value "${sp_pwd}" \
    --output none

az keyvault secret set \
    --name "${mlz_sp_kv_name}" \
    --subscription "${mlz_config_subid}" \
    --vault-name "${mlz_kv_name}" \
    --value "${sp_clientid}" \
    --output none

az keyvault secret set \
    --name "${mlz_sp_obj_name}" \
    --subscription "${mlz_config_subid}" \
    --vault-name "${mlz_kv_name}" \
    --value "${sp_objid}" \
    --output none

echo "INFO: MLZ resources for ${mlz_env_name} created!"

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

sp_exists () {

    sp_name=$1
    sp_property=$2

    sp_query="az ad sp show \
        --id http://${sp_name} \
        --query ${sp_property}"

    if ! $sp_query &> /dev/null; then

        sleep_time_in_seconds=10
        max_wait_in_minutes=3
        max_wait_in_seconds=180
        max_retries=$((max_wait_in_seconds/sleep_time_in_seconds))

        echo "INFO: maximum time to wait in seconds = ${max_wait_in_seconds}"
        echo "INFO: maximum number of retries = ${max_retries}"

        count=1

        while ! $sp_query &> /dev/null
        do

            echo "INFO: waiting for service principal ${sp_name} to populate property ${sp_property} (${count}/${max_retries})"
            echo "INFO: trying again in ${sleep_time_in_seconds} seconds..."
            sleep "${sleep_time_in_seconds}"

            if [[ ${count} -eq max_retries ]]; then
                error_log "ERROR: unable to determine ${sp_property} for the service principal ${sp_property} in ${max_wait_in_minutes} minutes. Investigate and re-run script."
                exit 1
            fi

            count=$((count +1))

        done
    fi

}

if [[ "$#" -lt 1 ]]; then
   usage
   exit 1
fi

mlz_tf_cfg=$(realpath "${1}")

# Source variables
. "${mlz_tf_cfg}"

# Create array of unique subscription IDs. The 'sed' command below search thru the source
# variables file looking for all lines that do not have a '#' in the line. If a line with
# a '#' is found, the '#' and ever character after it in the line is ignored. The output
# of what remains from the sed command is then piped to grep to find the words that match
# the pattern. These words are what make up the 'mlz_subs' array.
mlz_sub_pattern="mlz_.*._subid"
mlz_subs=$(< "${mlz_tf_cfg}" sed 's:#.*$::g' | grep -w "${mlz_sub_pattern}")
subs=()

# generate MLZ configuration names
. "${BASH_SOURCE%/*}/generate_names.sh" "${mlz_tf_cfg}"

echo "INFO: creating MLZ resources for ${mlz_env_name}..."

for mlz_sub in $mlz_subs
do
    # Grab value of variable
    mlz_sub_id=$(echo "${mlz_sub#*=}" | tr -d '"')
    if [[ ! "${subs[*]}" =~ ${mlz_sub_id} ]];then
        subs+=("${mlz_sub_id}")
    fi
done

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

    # Get Service Principal AppId
    # Added the sleep below to accomodate for the transient behavior where the Service Principal creation
    # is complete but an immediate query for it will fail. The sleep loop will run for 3 minutes and then
    # the script will exit due to a platform problem
    sp_exists "${mlz_sp_name}" "appId"

    sp_clientid=$(az ad sp show \
    --id "http://${mlz_sp_name}" \
    --query appId \
    --output tsv)

    # Get Service Principal ObjectId
    # Added the sleep below to accomodate for the transient behavior where the Service Principal creation
    # is complete but an immediate query for it will fail. The sleep loop will run for 3 minutes and then
    # the script will exit due to a platform problem
    sp_exists "${mlz_sp_name}" "objectId"

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
        --tags "DeploymentName=${mlz_env_name}" \
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

echo "INFO: MLZ resources for ${mlz_env_name} created!"

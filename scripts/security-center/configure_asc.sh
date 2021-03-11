#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC2154
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# Configures the landing zone subscriptions for Azure Security Center

set -e

PGM=$(basename "${0}")

if [[ "${PGM}" == "configure_asc.sh" && "$#" -lt 1 ]]; then
    echo "${PGM}: Initializes Azure Security Center Standard tier for Storage Accounts and Virtual Machines"
    echo "usage: ${PGM} <mlz tf config vars>"
    exit 1
elif [[ ! "${PGM}" == "mlz_tf_setup.sh" ]];then

    mlz_tf_cfg=$(realpath "${1}")

    # Source variables
    . "${mlz_tf_cfg}"

    mlz_sub_pattern="mlz_.*._subid"
    mlz_subs=$(< "$(realpath "${1}")" sed 's:#.*$::g' | grep -w "${mlz_sub_pattern}")
    subs=()

    for mlz_sub in $mlz_subs
    do
        # Grab value of variable
        mlz_sub_id=$(echo "${mlz_sub#*=}" | tr -d '"')
        if [[ ! "${subs[*]}" =~ ${mlz_sub_id} ]];then
            subs+=("${mlz_sub_id}")
        fi
    done
fi

# Configure Azure Security Center
for sub in "${subs[@]}"
do
    ascAutoProv=$(az security auto-provisioning-setting show \
        --subscription "${sub}" \
        --name "default" \
        --query autoProvision \
        --output tsv \
        --only-show-errors)
    if [[ ${ascAutoProv} == "Off" ]]; then

    # generate names
    . "${BASH_SOURCE%/*}"/generate_names.sh "${mlz_env_name}" "${sub}"

        # Create Resource Group for Log Analytics workspace
        if [[ -z $(az group show --name "${mlz_lawsrg_name}" --subscription "${sub}" --query name --output tsv) ]]; then
            echo "Resource Group does not exist...creating resource group ${mlz_lawsrg_name}"
            az group create \
                --subscription "${sub}" \
                --location "${mlz_config_location}" \
                --name "${mlz_lawsrg_name}"
        else
            echo "Resource Group ${mlz_lawsrg_name} already exists. Verify desired ASC configuration and re-run script"
            exit 1
        fi

        # Create Log Analytics workspace
        if [[ -z $(az monitor log-analytics workspace show --resource-group "${mlz_lawsrg_name}" --workspace-name "${mlz_laws_name}" --subscription "${sub}") ]]; then
            echo "Log Analytics workspace does not exist...creating workspace ${mlz_laws_name}"
            lawsId=$(az monitor log-analytics workspace create \
            --resource-group "${mlz_lawsrg_name}" \
            --workspace-name "${mlz_laws_name}" \
            --location "${mlz_config_location}" \
            --subscription "${sub}" \
            --query id \
            --output tsv)
        else
            echo "Log Analytics workspace ${mlz_laws_name} already exists. Verify desired ASC configuration and re-run script"
            exit 1
        fi

        # Set ASC pricing tier on Virtual Machines
        if [[ $(az security pricing show --name VirtualMachines --subscription "${sub}" --only-show-errors --query pricingTier --output tsv) == "Free" ]]; then
            echo "Setting ASC pricing tier for Virtual Machines to Standard..."
            az security pricing create \
            --name VirtualMachines \
            --subscription "${sub}" \
            --tier "Standard"
        fi

        # Set ASC pricing tier on Storage Accounts
        if [[ $(az security pricing show --name StorageAccounts --subscription "${sub}" --only-show-errors --query pricingTier --output tsv --only-show-errors) == "Free" ]]; then
            echo "Setting ASC pricing tier for Storage Accounts to Standard..."
            az security pricing create \
            --name StorageAccounts \
            --subscription "${sub}" \
            --tier "Standard"
        fi

        # Create default setting for ASC Log Analytics workspace
        if [[ -z $(az security workspace-setting show --name default --subscription "${sub}" --only-show-errors) ]];then

            sleep_time_in_seconds=30
            max_wait_in_minutes=30
            max_wait_in_seconds=$((max_wait_in_minutes*60))
            max_retries=$((max_wait_in_seconds/sleep_time_in_seconds))

            echo "Maximum time to wait in seconds = ${max_wait_in_seconds}"
            echo "Maximum number of retries = ${max_retries}"

            echo "ASC Log Analytics workspace setting does not exist...creating default setting"
            echo "This script will attempt to create the setting for ${max_wait_in_minutes} minutes and then timeout if the setting has not been created"

            az security workspace-setting create \
                --name "default" \
                --target-workspace "${lawsId}" \
                --subscription "${sub}"

            count=1

            # TODO (20210309): this could take an unusually long time and even fail altogether.
            # This is under investigation by the `az security` team.
            while [ -z "$(az security workspace-setting show --name default --subscription  "${sub}" --query workspaceId --output tsv --only-show-errors)" ]
            do

                echo "Waiting for ASC workspace setting to finish provisioning (${count}/${max_retries})"
                echo "Trying again in ${sleep_time_in_seconds} seconds..."
                sleep "${sleep_time_in_seconds}"

                if [[ ${count} -eq max_retries ]];then
                    echo "Provisioning the workspace setting has exceeded ${max_wait_in_minutes} minutes. Investigate and re-run script."
                    exit 1
                fi

                count=$((count + 1))

            done
        else
            echo "ASC already has a \"default\" Log Analytics workspace configuration. Verify desired ASC configuration and re-run script"
            exit 1
        fi

        # Set ASC auto-provisioning to On
        az security auto-provisioning-setting update \
            --auto-provision "On" \
            --subscription  "${sub}" \
            --name "default" \
            --only-show-errors
    else
        echo "ASC auto-provisioning is already set to \"On\". Verify desired ASC configuration and re-run script"
        exit 1
    fi
done
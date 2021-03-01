#!/bin/bash
# shellcheck disable=SC1090,SC2154
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC2154: "var is referenced but not assigned". These values come from an external file.

# Configures the landing zone subscriptions for Azure Security Center
# 20210228 @byboudre

PGM=$(basename "${0}")

if [[ "${PGM}" == "configure_asc.sh" && "$#" -lt 1 ]]; then
    echo "${PGM}: Initializes Azure Security Center Standard tier for Storage Accounts and Virtual Machines"
    echo "usage: ${PGM} <enclave name> <location>"
    exit 1
elif [[ ! "${PGM}" == "mlz_tf_setup.sh" ]];then
    echo var file sourced from configure_asc.sh
    source "$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"/src/core/mlz_tf_cfg.var
    enclave=$1
    location=$2
    subs+=("${tf_config_subid}")
    safeEnclave="${enclave//-}"

    for tier in ${!mlz_tier*}
    do
        if [[ ! "${subs[*]}" =~ ${!tier} ]]; then
            subs+=("${!tier}")
        fi
    done

    if [[ ! "${subs[*]}" =~ ${mlz_saca_subid} ]]; then
            subs+=("${mlz_saca_subid}")
    fi
fi

# Configure Azure Security Center
for sub in "${subs[@]}"
do
    ascAutoProv=$(az security auto-provisioning-setting show \
        --subscription "${sub}" \
        --name "default" \
        --query autoProvision \
        --output tsv)
    if [[ ${ascAutoProv} == "Off" ]]; then
        lawsRgName=rg-mlz-laws-${safeEnclave}
        safeSubId="${sub//-}"

        # Create Resource Group for Log Analytics workspace
        if [[ -z $(az group show --name "${lawsRgName}" --subscription "${sub}" --query name --output tsv) ]]; then
            echo Resource Group does not exist...creating resource group "${lawsRgName}"
            az group create \
                --subscription "${sub}" \
                --location "${location}" \
                --name "${lawsRgName}"
        else
            echo Resource Group "${lawsRgName}" already exists. Verify desired ASC configuration and re-run script
            exit 1
        fi

        # Create Log Analytics workspace
        if [[ -z $(az monitor log-analytics workspace show --resource-group "${lawsRgName}" --workspace-name "laws-${safeEnclave}-${safeSubId}" --subscription "${sub}") ]]; then
            echo Log Analytics workspace does not exist...creating workspace laws-"${safeEnclave}"-"${safeSubId}"
            lawsId=$(az monitor log-analytics workspace create \
            --resource-group "${lawsRgName}" \
            --workspace-name "laws-${safeEnclave}-${safeSubId}" \
            --location "${location}" \
            --subscription "${sub}" \
            --query id \
            --output tsv)
        else
            echo Log Analytics workspace "${lawsRgName}" already exists. Verify desired ASC configuration and re-run script
            exit 1
        fi

        # Set ASC pricing tier on Virtual Machines
        if [[ $(az security pricing show --name VirtualMachines --subscription "${sub}" --query pricingTier --output tsv --only-show-errors) == "Free" ]]; then
            echo Setting ASC pricing tier for Virtual Machines to Standard...
            az security pricing create \
            --name VirtualMachines \
            --subscription "${sub}" \
            --tier "Standard"
        fi

        # Set ASC pricing tier on Storage Accounts
        if [[ $(az security pricing show --name StorageAccounts --subscription "${sub}" --query pricingTier --output tsv --only-show-errors) == "Free" ]]; then
            echo Setting ASC pricing tier for Storage Accounts to Standard...
            az security pricing create \
            --name StorageAccounts \
            --subscription "${sub}" \
            --tier "Standard"
        fi

        # Create default setting for ASC Log Analytics workspace
        if [[ -z $(az security workspace-setting show --name default --subscription "${sub}" --only-show-errors) ]]; then
            echo ASC Log Analytics workspace setting does not exist...creating default setting
            echo Log Analytics ID = "${lawsId}"
            az security workspace-setting create \
                --name "default" \
                --target-workspace "${lawsId}" \
                --subscription "${sub}"
            count=0
            while [ -z "$(az security workspace-setting show --name default --subscription  "${sub}" --query workspaceId --output tsv --only-show-errors)" ]
            do
                echo Waiting for ASC work space setting to finish provisioning
                sleep 30
                count=$((count+1))
                echo Loop count = "${count}" 
            done
        else
            echo ASC already has a \"default\" Log Analytics workspace configuration. Verify desired ASC configuration and re-run script
            exit 1
        fi

        # Set ASC auto-provisioning to On
        az security auto-provisioning-setting update \
            --auto-provision "On" \
            --subscription  "${sub}" \
            --name "default" \
            --only-show-errors
    else
        echo ASC auto-provisioning is already set to \"On\". Verify desired ASC configuration and re-run script
        exit 1
    fi
done
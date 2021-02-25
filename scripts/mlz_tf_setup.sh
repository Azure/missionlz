#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC1091
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC1091: Not following. Shellcheck can't follow non-constant source.
#
# A script to configure a resource group that contains Terraform state and a secret store.

PGM=$(basename "${0}")

if [[ "$#" -lt 3 ]]; then
    echo "usage: ${PGM} <enclave name> <location> <terraform environment>"
    exit 1
fi

enclave=$1
location=$2
tf_environment=$3

# Check for dependencies
. "${BASH_SOURCE%/*}"/util/checkforazcli.sh

# Source variables
source "$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"/src/core/mlz_tf_cfg.var

##################################################
#
#   MLZ Deployment Setup
#
##################################################

# MLZ Terraform Names
tfCfgSubId="${tf_config_subid//-}" # remove hyphens in subscription ID for resource naming conventions
safeEnclave="${enclave//-}"
deployTfRgName=rg-mlz-tf_cfg-${safeEnclave}

rgName=rg-mlz-cfg-${safeEnclave}

spName=sp-tf-mlz-${safeEnclave}
spNameSecret=sp-tf-mlz-${safeEnclave}-clientid
spPwdSecret=sp-tf-mlz-${safeEnclave}-pwd

saNameByConvention=tfsa${safeEnclave}${tfCfgSubId}
saName=${saNameByConvention:0:24} # take the 24 characters of the storage account name
containerName=tfstate

kvNameByConvention=kvmlz${safeEnclave}${tfCfgSubId}
kvName=${kvNameByConvention:0:24} # take the 24 characters of the key vault name

# Create Azure AD application registration and Service Principal
echo "Verifying Service Principal is unique (${spName})"
if [[ -z $(az ad sp list --filter "displayName eq '${spName}'" --query "[].displayName" -o tsv) ]];then
    echo "Service Principal does not exist...creating"
    spPwd=$(az ad sp create-for-rbac \
        --name "http://${spName}" \
        --role Contributor \
        --scopes "/subscriptions/${tf_config_subid}" "/subscriptions/${mlz_saca_subid}" "/subscriptions/${mlz_tier0_subid}" "/subscriptions/${mlz_tier1_subid}" "/subscriptions/${mlz_tier2_subid}" \
        --query password \
        --output tsv)
else
    echo "Service Principal named ${spName} already exists. This must be a unique Service Principal for your use only. Try again with a new enclave name. Exiting script."
    exit
fi

# Get Service Principal AppId
spClientId=$(az ad sp show \
    --id "http://${spName}" \
    --query appId \
    --output tsv)

# Get Service Principal ObjectId
spObjectId=$(az ad sp show \
    --id "http://${spName}" \
    --query objectId \
    --output tsv)

# Validate or create Terraform Config resource group
if [[ -z $(az group show --name "${deployTfRgName}" --subscription "${tf_config_subid}" --query name --output tsv) ]];then
    echo "Resource Group does not exist...creating resource group ${deployTfRgName}"
    az group create \
        --subscription "${tf_config_subid}" \
        --location "${location}" \
        --name "${deployTfRgName}"
else
    echo "Resource Group already exsits...getting resource group"
fi

# Create Key Vault
if [[ -z $(az keyvault show --name "${kvName}" --subscription "${tf_config_subid}" --query name --output tsv) ]];then
    echo "Key Vault ${kvName} does not exist...creating Key Vault"
    az keyvault create \
        --name "${kvName}" \
        --subscription "${tf_config_subid}" \
        --resource-group "${deployTfRgName}" \
        --location "${location}" \
        --output none
    echo "Key Vault ${kvName} created!"
fi

# Create Key Vault Access Policy for Service Principal
echo "Setting Access Policy for Service Principal..."
az keyvault set-policy \
    --name "${kvName}" \
    --subscription "${tf_config_subid}" \
    --resource-group "${deployTfRgName}" \
    --object-id "${spObjectId}" \
    --secret-permissions get list set \
    --output none
echo "Access Policy for Service Principal set!"

# Set Key Vault Secrets
echo "Updating KeyVault with Service Principal secrets..."
az keyvault secret set \
    --name "${spPwdSecret}" \
    --subscription "${tf_config_subid}" \
    --vault-name "${kvName}" \
    --value "${spPwd}" \
    --output none

az keyvault secret set \
    --name "${spNameSecret}" \
    --subscription "${tf_config_subid}" \
    --vault-name "${kvName}" \
    --value "${spClientId}" \
    --output none
echo "KeyVault updated with Service Principal secrets!"

##################################################
#
#   SACA-hub Deployment Setup
#
##################################################

# SACA-hub Terraform Names
sacaSubId="${mlz_saca_subid//-}" # remove hyphens in subscription ID for resource naming conventions
sacaTfRgName=rg-mlz-tf_saca-${enclave}
sacasaNameByConvention=tfsasaca${enclave}${sacaSubId}
sacasaName=${sacasaNameByConvention:0:24} # take the 24 characters of the storage account name
containerName=tfstate

# Create SACA-hub Resource Group and Storage Account for Terraform State files
echo "Validating Resource Group for Terraform state..."
if [[ -z $(az group show --name "${sacaTfRgName}" --subscription "${mlz_saca_subid}" --query name --output tsv) ]];then
    echo "Resource Group does not exist...creating resource group ${sacaTfRgName}"
    az group create \
        --subscription "${mlz_saca_subid}" \
        --location "${location}" \
        --name "${sacaTfRgName}"
else
    echo "Resource Group already exsits...getting resource group"
fi

echo "Validating Storage Account for Terraform state..."
if [[ -z $(az storage account show --name "${sacasaName}" --subscription "${mlz_saca_subid}" --query name --output tsv) ]];then
    echo "Storage Account does not exist...creating storage account ${sacasaName}"
    az storage account create \
        --name "${sacasaName}" \
        --subscription "${mlz_saca_subid}" \
        --resource-group "${sacaTfRgName}" \
        --location "${location}" \
        --sku Standard_LRS \
        --output none

    sacasaKey=$(az storage account keys list \
        --account-name "${sacasaName}" \
        --subscription "${mlz_saca_subid}" \
        --resource-group "${sacaTfRgName}" \
        --query "[?keyName=='key1'].value" \
        --output tsv)

    az storage container create \
        --name "${containerName}" \
        --subscription "${mlz_saca_subid}" \
        --resource-group "${sacaTfRgName}" \
        --account-name "${sacasaName}" \
        --account-key "${sacasaKey}" \
        --output none
    echo "Storage account and container for Terraform state created!"
else
    echo "Storage Account already exsits"
fi

# Create SACA-hub config.vars file
configvars="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"/src/core/saca-hub/config.vars
rm -f "$configvars"
touch "$configvars"
{
    echo "tenant_id=${mlz_tenantid}"
    echo "mlz_cfg_sub_id=${tf_config_subid}"
    echo "sub_id=${mlz_saca_subid}"
    echo "enclave=${enclave}"
    echo "location=${location}"
    echo "tf_be_rg_name=${sacaTfRgName}"
    echo "tf_be_sa_name=${sacasaName}"
    echo "mlz_cfg_kv_name=${kvName}"
    echo "sp_client_id_secret_name=${spNameSecret}"
    echo "sp_client_pwd_secret_name=${spPwdSecret}"
    echo "environment=${tf_environment}"
    echo "container_name=tfstate"
} >> "$configvars"

##################################################
#
#   Tier-0 Deployment Setup
#
##################################################

# Tier-0 Terraform Names
tier0SubId="${mlz_tier0_subid//-}" # remove hyphens in subscription ID for resource naming conventions
tier0TfRgName=rg-mlz-tf_tier0-${enclave}
t0saNameByConvention=tfsatier0${enclave}${tier0SubId}
t0saName=${t0saNameByConvention:0:24} # take the 24 characters of the storage account name
containerName=tfstate

# Create Tier-0 Resource Group and Storage Account for Terraform State files
echo "Validating Resource Group for Terraform state..."
if [[ -z $(az group show --name "${tier0TfRgName}" --subscription "${mlz_tier0_subid}" --query name --output tsv) ]];then
    echo "Resource Group does not exist...creating resource group ${tier0TfRgName}"
    az group create \
        --subscription "${mlz_tier0_subid}" \
        --location "${location}" \
        --name "${tier0TfRgName}"
else
    echo "Resource Group already exsits...getting resource group"
fi

echo "Validating Storage Account for Terraform state..."
if [[ -z $(az storage account show --name "${t0saName}" --subscription "${mlz_tier0_subid}" --query name --output tsv) ]];then
    echo "Storage Account does not exist...creating storage account ${t0saName}"
    az storage account create \
        --name "${t0saName}" \
        --subscription "${mlz_tier0_subid}" \
        --resource-group "${tier0TfRgName}" \
        --location "${location}" \
        --sku Standard_LRS \
        --output none

    t0saKey=$(az storage account keys list \
        --account-name "${t0saName}" \
        --subscription "${mlz_tier0_subid}" \
        --resource-group "${tier0TfRgName}" \
        --query "[?keyName=='key1'].value" \
        --output tsv)

    az storage container create \
        --name "${containerName}" \
        --subscription "${mlz_tier0_subid}" \
        --resource-group "${tier0TfRgName}" \
        --account-name "${t0saName}" \
        --account-key "${t0saKey}" \
        --output none
    echo "Storage account and container for Terraform state created!"
else
    echo "Storage Account already exsits"
fi

# Create Tier-0 config.vars file
configvars="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"/src/core/tier-0/config.vars
rm -f "$configvars"
touch "$configvars"
{
    echo "tenant_id=${mlz_tenantid}"
    echo "mlz_cfg_sub_id=${tf_config_subid}"
    echo "sub_id=${mlz_tier0_subid}"
    echo "enclave=${enclave}"
    echo "location=${location}"
    echo "tf_be_rg_name=${tier0TfRgName}"
    echo "tf_be_sa_name=${t0saName}"
    echo "mlz_cfg_kv_name=${kvName}"
    echo "sp_client_id_secret_name=${spNameSecret}"
    echo "sp_client_pwd_secret_name=${spPwdSecret}"
    echo "environment=${tf_environment}"
    echo "container_name=tfstate"
} >> "$configvars"

##################################################
#
#   Tier-1 Deployment Setup
#
##################################################

# Tier-1 Terraform Names
tier1SubId="${mlz_tier1_subid//-}" # remove hyphens in subscription ID for resource naming conventions
tier1TfRgName=rg-mlz-tf_tier1-${enclave}
t1saNameByConvention=tfsatier1${enclave}${tier1SubId}
t1saName=${t1saNameByConvention:0:24} # take the 24 characters of the storage account name
containerName=tfstate

# Create Tier-1 Resource Group and Storage Account for Terraform State files
echo "Validating Resource Group for Terraform state..."
if [[ -z $(az group show --name "${tier1TfRgName}" --subscription "${mlz_tier1_subid}" --query name --output tsv) ]];then
    echo "Resource Group does not exist...creating resource group ${tier1TfRgName}"
    az group create \
        --subscription "${mlz_tier1_subid}" \
        --location "${location}" \
        --name "${tier1TfRgName}"
else
    echo "Resource Group already exsits...getting resource group"
fi

echo "Validating Storage Account for Terraform state..."
if [[ -z $(az storage account show --name "${t1saName}" --subscription "${mlz_tier1_subid}" --query name --output tsv) ]];then
    echo "Storage Account does not exist...creating storage account ${t1saName}"
    az storage account create \
        --name "${t1saName}" \
        --subscription "${mlz_tier1_subid}" \
        --resource-group "${tier1TfRgName}" \
        --location "${location}" \
        --sku Standard_LRS \
        --output none

    t1saKey=$(az storage account keys list \
        --account-name "${t1saName}" \
        --subscription "${mlz_tier1_subid}" \
        --resource-group "${tier1TfRgName}" \
        --query "[?keyName=='key1'].value" \
        --output tsv)

    az storage container create \
        --name "${containerName}" \
        --subscription "${mlz_tier1_subid}" \
        --resource-group "${tier1TfRgName}" \
        --account-name "${t1saName}" \
        --account-key "${t1saKey}" \
        --output none
    echo "Storage account and container for Terraform state created!"
else
    echo "Storage Account already exsits"
fi

# Create Tier-1 config.vars file
configvars="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"/src/core/tier-1/config.vars
rm -f "$configvars"
touch "$configvars"
{
    echo "tenant_id=${mlz_tenantid}"
    echo "mlz_cfg_sub_id=${tf_config_subid}"
    echo "sub_id=${mlz_tier1_subid}"
    echo "enclave=${enclave}"
    echo "location=${location}"
    echo "tf_be_rg_name=${tier1TfRgName}"
    echo "tf_be_sa_name=${t1saName}"
    echo "mlz_cfg_kv_name=${kvName}"
    echo "sp_client_id_secret_name=${spNameSecret}"
    echo "sp_client_pwd_secret_name=${spPwdSecret}"
    echo "environment=${tf_environment}"
    echo "container_name=tfstate"
} >> "$configvars"

##################################################
#
#   Tier-2 Deployment Setup
#
##################################################

# Tier-2 Terraform Names
tier2SubId="${mlz_tier2_subid//-}" # remove hyphens in subscription ID for resource naming conventions
tier2TfRgName=rg-mlz-tf_tier2-${enclave}
t2saNameByConvention=tfsatier2${enclave}${tier2SubId}
t2saName=${t2saNameByConvention:0:24} # take the 24 characters of the storage account name
containerName=tfstate

# Create Tier-2 Resource Group and Storage Account for Terraform State files
echo "Validating Resource Group for Terraform state..."
if [[ -z $(az group show --name "${tier2TfRgName}" --subscription "${mlz_tier2_subid}" --query name --output tsv) ]];then
    echo "Resource Group does not exist...creating resource group ${tier2TfRgName}"
    az group create \
        --subscription "${mlz_tier2_subid}" \
        --location "${location}" \
        --name "${tier2TfRgName}"
else
    echo "Resource Group already exsits...getting resource group"
fi

echo "Validating Storage Account for Terraform state..."
if [[ -z $(az storage account show --name "${t2saName}" --subscription "${mlz_tier2_subid}" --query name --output tsv) ]];then
    echo "Storage Account does not exist...creating storage account ${t2saName}"
    az storage account create \
        --name "${t2saName}" \
        --subscription "${mlz_tier2_subid}" \
        --resource-group "${tier2TfRgName}" \
        --location "${location}" \
        --sku Standard_LRS \
        --output none

    t2saKey=$(az storage account keys list \
        --account-name "${t2saName}" \
        --subscription "${mlz_tier2_subid}" \
        --resource-group "${tier2TfRgName}" \
        --query "[?keyName=='key1'].value" \
        --output tsv)

    az storage container create \
        --name "${containerName}" \
        --subscription "${mlz_tier2_subid}" \
        --resource-group "${tier2TfRgName}" \
        --account-name "${t2saName}" \
        --account-key "${t2saKey}" \
        --output none
    echo "Storage account and container for Terraform state created!"
else
    echo "Storage Account already exsits"
fi

# Create Tier-2 config.vars file
configvars="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"/src/core/tier-2/config.vars
rm -f "$configvars"
touch "$configvars"
{
    echo "tenant_id=${mlz_tenantid}"
    echo "mlz_cfg_sub_id=${tf_config_subid}"
    echo "sub_id=${mlz_tier2_subid}"
    echo "enclave=${enclave}"
    echo "location=${location}"
    echo "tf_be_rg_name=${tier2TfRgName}"
    echo "tf_be_sa_name=${t2saName}"
    echo "mlz_cfg_kv_name=${kvName}"
    echo "sp_client_id_secret_name=${spNameSecret}"
    echo "sp_client_pwd_secret_name=${spPwdSecret}"
    echo "environment=${tf_environment}"
    echo "container_name=tfstate"
} >> "$configvars"
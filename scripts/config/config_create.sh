#!/bin/bash
#
# Create Terraform module config resources

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "${0}: Create Terraform module config resources"
  error_log "usage: ${0} <mlz tf config vars> <enclave name> <location> <tf subscription id> <path to terraform module>"
}

if [[ "$#" -lt 4 ]]; then
   usage
   exit 1
fi

mlz_tf_cfg=$(realpath "${1}")
enclave_name=$2
location=$3
tf_sub_id=$4
tf_dir=$(realpath "${5}")

# source MLZ config vars
. "${mlz_tf_cfg}"

# derive TF names from the terraform directory
tf_name=$(basename "${tf_dir}")

# generate names
. "${BASH_SOURCE%/*}"/generate_names.sh "${tf_config_subid}" "${enclave_name}" "${tf_sub_id}" "${tf_name}"

# create TF Resource Group and Storage Account for Terraform State files
echo "Validating Resource Group for Terraform state..."
if [[ -z $(az group show --name "${tf_rg_name}" --subscription "${tf_sub_id}" --query name --output tsv) ]];then
    echo "Resource Group does not exist...creating resource group ${tf_rg_name}"
    az group create \
        --subscription "${tf_sub_id}" \
        --location "${location}" \
        --name "${tf_rg_name}"
else
    echo "Resource Group already exsits...getting resource group"
fi

echo "Validating Storage Account for Terraform state..."
if [[ -z $(az storage account show --name "${tf_sa_name}" --subscription "${tf_sub_id}" --query name --output tsv) ]];then
    echo "Storage Account does not exist...creating storage account ${tf_sa_name}"
    az storage account create \
        --name "${tf_sa_name}" \
        --subscription "${tf_sub_id}" \
        --resource-group "${tf_rg_name}" \
        --location "${location}" \
        --sku Standard_LRS \
        --output none

    sa_key=$(az storage account keys list \
        --account-name "${tf_sa_name}" \
        --subscription "${tf_sub_id}" \
        --resource-group "${tf_rg_name}" \
        --query "[?keyName=='key1'].value" \
        --output tsv)

    az storage container create \
        --name "${container_name}" \
        --subscription "${tf_sub_id}" \
        --resource-group "${tf_rg_name}" \
        --account-name "${tf_sa_name}" \
        --account-key "${sa_key}" \
        --output none
    echo "Storage account and container for Terraform state created!"
else
    echo "Storage Account already exsits"
fi

# Create a config.vars file
config_vars="${tf_dir}/config.vars"
rm -f "$config_vars"
touch "$config_vars"
{
    echo "tenant_id=${mlz_tenantid}"
    echo "mlz_cfg_sub_id=${tf_config_subid}"
    echo "mlz_cfg_kv_name=${mlz_kv_name}"
    echo "sub_id=${tf_sub_id}"
    echo "enclave=${mlz_enclave_name}"
    echo "location=${location}"
    echo "tf_be_tf_rg_name=${tf_rg_name}"
    echo "tf_be_sa_name=${tf_sa_name}"
    echo "sp_client_id_secret_name=${mlz_sp_kv_name}"
    echo "sp_client_pwd_secret_name=${mlz_sp_kv_password}"
    echo "environment=${tf_environment}"
    echo "container_name=${container_name}"
} >> "$config_vars"

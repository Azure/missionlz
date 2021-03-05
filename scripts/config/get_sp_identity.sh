#!/bin/bash
#
# Given a MLZTF config.vars file, export a mlz_client_id and mlz_client_secret

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "get_sp_identity.sh: Given a MLZTF config.vars file, export a mlz_client_id and mlz_client_secret"
  error_log "usage: get_sp_identity.sh <MLZTF config.vars>"
}

if [[ "$#" -lt 1 ]]; then
   usage
   exit 1
fi

config_vars=$1

# Validate configuration file exists
. "${BASH_SOURCE%/*}"/util/checkforfile.sh \
   "${config_vars}" \
   "The configuration file ${config_vars} is empty or does not exist. You may need to run MLZ setup."

# Source configuration file
. "${config_vars}"

if [[ -z $(az keyvault secret show --name "${sp_client_id_secret_name}" --vault-name "${mlz_cfg_kv_name}" --subscription "${mlz_cfg_sub_id}") ]]; then
   echo The Key Vault secret "${sp_client_id_secret_name}" does not exist...validate config.vars file and re-run script
   exit 1
else
   export client_id=$(az keyvault secret show \
      --name "${sp_client_id_secret_name}" \
      --vault-name "${mlz_cfg_kv_name}" \
      --subscription "${mlz_cfg_sub_id}" \
      --query value \
      --output tsv)
fi

# Query Key Vault for Service Principal Password
if [[ -z $(az keyvault secret show --name "${sp_client_pwd_secret_name}" --vault-name "${mlz_cfg_kv_name}" --subscription "${mlz_cfg_sub_id}") ]]; then
   echo The Key Vault secret "${sp_client_pwd_secret_name}" does not exist...validate config.vars file and re-run script
   exit 1
else
   export client_secret=$(az keyvault secret show \
      --name "${sp_client_pwd_secret_name}" \
      --vault-name "${mlz_cfg_kv_name}" \
      --subscription "${mlz_cfg_sub_id}" \
      --query value \
      --output tsv)
fi

# Validate Service Principal exists
echo Verifying Service Principal with Client ID: "${client_id}"
if [[ -z $(az ad sp list --filter "appId eq '${client_id}'") ]]; then
    echo Service Principal with Client ID "${client_id}" could not be found...validate config.vars file and re-run script
    exit 1
fi

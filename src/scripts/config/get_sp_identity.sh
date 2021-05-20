#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC2154
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# Given a MLZTF config.vars file, export a mlz_client_id and mlz_client_secret

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "get_sp_identity.sh: Given a MLZTF config.vars file, export a mlz_client_id, mlz_client_secret, and mlz_object_id"
  error_log "usage: get_sp_identity.sh <MLZTF config.vars>"
}

if [[ "$#" -lt 1 ]]; then
   usage
   exit 1
fi

config_vars=$1

# Validate configuration file exists
. "$(dirname "${BASH_SOURCE%/*}")/util/checkforfile.sh" \
   "${config_vars}" \
   "The configuration file ${config_vars} is empty or does not exist. You may need to run MLZ setup."

# Source configuration file
. "${config_vars}"

# query for service principal client ID
kv_id_exists="az keyvault secret show \
    --name ${sp_client_id_secret_name} \
    --vault-name ${mlz_cfg_kv_name} \
    --subscription ${mlz_cfg_sub_id}"

if ! $kv_id_exists &> /dev/null; then
   echo "The Key Vault secret ${sp_client_id_secret_name} does not exist...validate config.vars file and re-run script"
   exit 1
else
   client_id=$(az keyvault secret show \
      --name "${sp_client_id_secret_name}" \
      --vault-name "${mlz_cfg_kv_name}" \
      --subscription "${mlz_cfg_sub_id}" \
      --query value \
      --output tsv)
   export client_id
fi

# query for service principal password
kv_pwd_exists="az keyvault secret show \
    --name ${sp_client_pwd_secret_name} \
    --vault-name ${mlz_cfg_kv_name} \
    --subscription ${mlz_cfg_sub_id}"

if ! $kv_pwd_exists &> /dev/null; then
   echo "The Key Vault secret ${sp_client_pwd_secret_name} does not exist...validate config.vars file and re-run script"
   exit 1
else
   client_secret=$(az keyvault secret show \
      --name "${sp_client_pwd_secret_name}" \
      --vault-name "${mlz_cfg_kv_name}" \
      --subscription "${mlz_cfg_sub_id}" \
      --query value \
      --output tsv)
   export client_secret
fi

# query for service principal object ID
kv_obj_id_exists="az keyvault secret show \
    --name ${sp_object_id_secret_name} \
    --vault-name ${mlz_cfg_kv_name} \
    --subscription ${mlz_cfg_sub_id}"
if ! $kv_obj_id_exists &> /dev/null; then
   echo "The Key Vault secret ${sp_object_id_secret_name} does not exist...validate config.vars file and re-run script"
   exit 1
else
   object_id=$(az keyvault secret show \
      --name "${sp_object_id_secret_name}" \
      --vault-name "${mlz_cfg_kv_name}" \
      --subscription "${mlz_cfg_sub_id}" \
      --query value \
      --output tsv)
   export object_id
fi

# Validate Service Principal exists
sp_exists="az ad sp show \
   --id ${client_id}"

if ! $sp_exists &> /dev/null; then
   echo "Service Principal with Client ID ${client_id} could not be found...validate config.vars file and re-run script"
   exit 1
fi

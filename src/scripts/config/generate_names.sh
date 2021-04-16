#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC1091,SC2154
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC1091: Not following. Shellcheck can't follow non-constant source.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# Generate MLZ resource names
# rules from: https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "generate_names.sh: Generate MLZ resource names"
  error_log "usage: generate_names.sh <mlz config> <tf sub id> <tf name>"
}

if [[ "$#" -lt 1 ]]; then
   usage
   exit 1
fi

mlz_config=$(realpath "${1}")
tf_sub_id_raw=${2:-notset}
tf_name_raw=${3:-notset}

# source variables from MLZ config
. "${mlz_config}"

# remove hyphens for resource naming restrictions
# in the future, do more cleansing
mlz_sub_id_clean=$(echo ${mlz_config_subid} | tr -cd '[:alnum:]')
mlz_env_name_clean=$(echo ${mlz_env_name} | tr -cd '[:alnum:]')

# Universal names
export container_name="tfstate"

# MLZ naming patterns
mlz_prefix="mlz"
mlz_suffix="${mlz_env_name_clean}${mlz_sub_id_clean}"

mlz_rg_name_full="${mlz_prefix}-config-${mlz_env_name_clean}"
mlz_sp_name_full="${mlz_prefix}-terraform-sp-${mlz_env_name_clean}"
mlz_kv_name_full="${mlz_prefix}kv${mlz_suffix}"
mlz_acr_name_full="${mlz_prefix}acr${mlz_suffix}"
mlz_fe_app_name_full="${mlz_prefix}-frontend-app-${mlz_env_name_clean}"
mlz_instance_name_full="${mlz_prefix}feinstance${mlz_suffix}"
mlz_dns_name_full="${mlz_prefix}dep${mlz_suffix}"

# Name MLZ config resources
export mlz_config_tag="${mlz_prefix}config${mlz_suffix}"
export mlz_rg_name="${mlz_rg_name_full:0:63}"
export mlz_sp_name="${mlz_sp_name_full:0:120}"
export mlz_sp_kv_name="serviceprincipal-clientid"
export mlz_sp_kv_password="serviceprincipal-pwd"
export mlz_login_app_kv_name="login-app-clientid"
export mlz_login_app_kv_password="login-app-pwd"
export mlz_kv_name="${mlz_kv_name_full:0:24}"
export mlz_acr_name="${mlz_acr_name_full:0:50}"
export mlz_fe_app_name="${mlz_fe_app_name_full:0:120}"
export mlz_instance_name="${mlz_instance_name_full:0:64}"
export mlz_dns_name="${mlz_dns_name_full:0:60}"

if [[ $tf_name_raw != "notset" ]]; then
  # remove hyphens for resource naming restrictions
  # in the future, do more cleansing
  tf_sub_id_clean=$(echo ${tf_sub_id_raw} | tr -cd '[:alnum:]')
  tf_name=$(echo ${tf_name_raw} | tr -cd '[:alnum:]')

  # TF naming patterns
  tf_rg_name_full="${mlz_prefix}-tfstate-${tf_name}-${mlz_env_name_clean}"
  tf_sa_name_full="tfsa${tf_name}${mlz_suffix}"

  # Name TF config resources
  export tf_rg_name="${tf_rg_name_full:0:63}"
  export tf_sa_name="${tf_sa_name_full:0:24}"
fi

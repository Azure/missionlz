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
mlz_sub_id_clean="${mlz_config_subid//-}"
mlz_env_name_clean="${mlz_env_name//-}"

# Universal names
export container_name="tfstate"

# MLZ naming patterns
mlz_prefix="mlz-tf"
mlz_sp_name_full="sp-${mlz_prefix}-${mlz_env_name_clean}"
mlz_sa_name_full="mlztfsa${mlz_env_name_clean}${mlz_sub_id_clean}"
mlz_kv_name_full="mlzkv${mlz_env_name_clean}${mlz_sub_id_clean}"
mlz_acr_name_full="mlzacr${mlz_env_name_clean}${mlz_sub_id_clean}"
mlz_fe_app_name_full="mlzfeapp${mlz_env_name_clean}${mlz_sub_id_clean}"
mlz_instance_name_full="mlzfeinstance${mlz_env_name_clean}${mlz_sub_id_clean}"
mlz_dns_name_full="mlzdep${mlz_env_name_clean}${mlz_sub_id_clean}"

# Name MLZ config resources
export mlz_rg_name="rg-${mlz_prefix}-${mlz_env_name_clean}"
export mlz_sp_name="${mlz_sp_name_full}"
export mlz_sp_kv_name="serviceprincipal-clientid"
export mlz_sp_kv_password="serviceprincipal-pwd"
export mlz_login_app_kv_name="login-app-clientid"
export mlz_login_app_kv_password="login-app-pwd"
export mlz_sa_name="${mlz_sa_name_full:0:24}" # take the 24 characters of the storage account name
export mlz_kv_name="${mlz_kv_name_full:0:24}" # take the 24 characters of the key vault name
export mlz_acr_name="${mlz_acr_name_full:0:24}"
export mlz_fe_app_name="${mlz_fe_app_name_full:0:24}"
export mlz_instance_name="${mlz_instance_name_full:0:24}"
export mlz_dns_name="${mlz_dns_name_full:0:24}"

if [[ $tf_name_raw != "notset" ]]; then
  # remove hyphens for resource naming restrictions
  # in the future, do more cleansing
  tf_sub_id_clean="${tf_sub_id_raw//-}"
  tf_name="${tf_name_raw//-}"

  # TF naming patterns
  tf_prefix="tf-${tf_name}"
  tf_sa_name_full="tfsa${tf_name}${mlz_env_name_clean}${tf_sub_id_clean}"

  # Name TF config resources
  export tf_rg_name="rg-${tf_prefix}-${mlz_env_name_clean}"
  export tf_sa_name="${tf_sa_name_full:0:24}" # take the 24 characters of the storage account name
fi

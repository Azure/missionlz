#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC1091,SC2002,SC2154
#
# Generate MLZ resource names
# rules from: https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "generate_names.sh: Generate MLZ resource names"
  error_log "usage: generate_names.sh <mlz config> <tf name>"
}

if [[ "$#" -lt 1 ]]; then
   usage
   exit 1
fi

create_resource_group_names() {
  export mlz_config_tag="${mlz_prefix}-${env_name_alphanumeric}-config"
  export mlz_rg_name="${mlz_config_tag:0:63}"
}

create_service_principal_name(){
  local mlz_sp_name_full="${mlz_prefix}-${env_name_alphanumeric}-terraform-sp"
  export mlz_sp_name="${mlz_sp_name_full:0:120}"
}

create_keyvault_names(){
  local mlz_kv_name_full="${mlz_prefix}${env_name_alphanumeric}kv${randomish_identifier}"
  export mlz_kv_name="${mlz_kv_name_full:0:24}"

  export mlz_sp_kv_name="serviceprincipal-clientid"
  export mlz_sp_kv_password="serviceprincipal-pwd"
  export mlz_sp_obj_name="serviceprincipal-objectid"
  export mlz_login_app_kv_name="login-app-clientid"
  export mlz_login_app_kv_password="login-app-pwd"
}

create_container_registry_names(){
  local mlz_acr_name_full="${mlz_prefix}${env_name_alphanumeric}acr${randomish_identifier}"
  export mlz_acr_name="${mlz_acr_name_full:0:50}"

  local mlz_fe_app_name_full="${mlz_prefix}-${env_name_alphanumeric}-frontend-app"
  export mlz_fe_app_name="${mlz_fe_app_name_full:0:120}"

  local mlz_instance_name_full="${mlz_prefix}${env_name_alphanumeric}feinstance${randomish_identifier}"
  export mlz_instance_name="${mlz_instance_name_full:0:63}"

  local mlz_dns_name_full="${mlz_prefix}${env_name_alphanumeric}dns${randomish_identifier}"
  export mlz_dns_name="${mlz_dns_name_full:0:60}"
}

create_terraform_backend_names() {
  if [[ $tf_name_raw != "notset" ]]; then
    tf_name=$(echo "${tf_name_raw}" | tr -cd '[:alnum:]')

    local tfstate_resource_group_name="${mlz_prefix}-${env_name_alphanumeric}-tfstate-${tf_name}"
    export tf_rg_name="${tfstate_resource_group_name:0:63}"

    local tfstate_storage_account_name="tfsa${tf_name}${env_name_alphanumeric}${randomish_identifier}"
    valid_tfstate_storage_account_name=$(echo "${tfstate_storage_account_name:0:24}" | tr '[:upper:]' '[:lower:]')
    export tf_sa_name=${valid_tfstate_storage_account_name}

    export container_name="tfstate"
  fi
}

##########
# main
##########

mlz_config=$(realpath "${1}")
tf_name_raw=${2:-notset}

# source variables from MLZ config
. "${mlz_config}"

mlz_prefix="mlz"

env_name_alphanumeric=$(echo "${mlz_env_name}" | tr -cd '[:alnum:]')
randomish_identifier=${mlz_config_subid:0:8} # take the first octet in the subscription ID

create_resource_group_names
create_service_principal_name
create_keyvault_names
create_container_registry_names
create_terraform_backend_names

#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
#

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "${0}: Generate MLZ resource names"
  error_log "usage: ${0} <mlz config subscription ID> <enclave name> <optional tf sub id> <optional tf name>"
}

if [[ "$#" -lt 2 ]]; then
   usage
   exit 1
fi

mlz_sub_id_raw=$1
mlz_enclave_name_raw=$2

tf_sub_id_raw=${3:-notset}
tf_name_raw=${4:-notset}

# remove hyphens for resource naming restrictions
# in the future, do more cleansing
mlz_sub_id_clean="${mlz_sub_id_raw//-}"
mlz_enclave_name="${mlz_enclave_name_raw//-}"

# Universal names
export container_name="tfstate"

# MLZ naming patterns
mlz_prefix="mlz-tf"
mlz_sp_name_full="sp-${mlz_prefix}-${mlz_enclave_name}"
mlz_sa_name_full="mlztfsa${mlz_enclave_name}${mlz_sub_id_clean}"
mlz_kv_name_full="mlzkv${mlz_enclave_name}${mlz_sub_id_clean}"

# Name MLZ config resources
export mlz_rg_name="rg-${mlz_prefix}-${mlz_enclave_name}"
export mlz_sp_name="${mlz_sp_name_full}"
export mlz_sp_kv_name="${mlz_sp_name_full}-clientid"
export mlz_sp_kv_password="${mlz_sp_name_full}-pwd"
export mlz_sa_name="${mlz_sa_name_full:0:24}" # take the 24 characters of the storage account name
export mlz_kv_name="${mlz_kv_name_full:0:24}" # take the 24 characters of the key vault name

if [[ $tf_name_raw != "notset" ]]; then
  # remove hyphens for resource naming restrictions
  # in the future, do more cleansing
  tf_sub_id_clean="${tf_sub_id_raw//-}"
  tf_name="${tf_name_raw//-}"

  # TF naming patterns
  tf_prefix="tf-${tf_name}"
  tf_sa_name_full="tfsa${tf_name}${mlz_enclave_name}${tf_sub_id_clean}"

  # Name TF config resources
  export tf_rg_name="rg-${tf_prefix}-${mlz_enclave_name}"
  export tf_sa_name="${tf_sa_name_full:0:24}" # take the 24 characters of the storage account name
fi

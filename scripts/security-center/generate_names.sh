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
  error_log "usage: ${0} <enclave name>"
}

if [[ "$#" -ne 1 ]]; then
   usage
   exit 1
fi

mlz_enclave_name_raw=$1

# remove hyphens for resource naming restrictions
# in the future, do more cleansing
mlz_enclave_name="${mlz_enclave_name_raw//-}"

# Name MLZ config resources
export mlz_lawsrg_name="rg-mlz-laws-${mlz_enclave_name}"
export mlz_laws_prefix="laws-${mlz_enclave_name}"
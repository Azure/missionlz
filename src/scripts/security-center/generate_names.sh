#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Generate Azure Security Center resource names

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "${0}: Generate Security Center resource names"
  error_log "usage: ${0} <enclave name> <sub ID>"
}

if [[ "$#" -ne 2 ]]; then
   usage
   exit 1
fi

mlz_enclave_name_raw=$1
sub_raw=$2

# remove hyphens for resource naming restrictions
# in the future, do more cleansing
mlz_enclave_name="${mlz_enclave_name_raw//-}"
safeSubId="${sub_raw//-}"


# Name MLZ config resources
export mlz_lawsrg_name="rg-mlz-laws-${mlz_enclave_name}"
export mlz_laws_name="laws-${mlz_enclave_name}-${safeSubId}"
#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# validate that ARM_CLIENT_ID and ARM_CLIENT_SECRET environment variables are set

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "checkforarmcredential.sh: validate that ARM_CLIENT_ID and ARM_CLIENT_SECRET environment variables are set"
  error_log "usage: checkforarmcredential.sh <error message>"
}

if [[ "$#" -lt 1 ]]; then
   usage
   exit 1
fi

error_message=$1

if [[ -z $ARM_CLIENT_ID || -z $ARM_CLIENT_SECRET ]]; then
  error_log "${error_message}"
  echo "INFO: You can set these environment variables with 'export ARM_CLIENT_ID=\"YOUR_CLIENT_ID\"' and 'export ARM_CLIENT_SECRET=\"YOUR_CLIENT_SECRET\"'"
  exit 1
fi
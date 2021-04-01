#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC2154
# SC1090: Can't follow non-constant source. These values come from an external file.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# Get the tenant ID from some MLZ configuration file and login using known Service Principal credentials

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "login_azcli.sh: login using known Service Principal credentials into a given tenant"
  error_log "usage: login_azcli.sh <tenant ID> <service principal ID> <service principal password>"
}

if [[ "$#" -lt 3 ]]; then
   usage
   exit 1
fi

tenant_id=$1
sp_id=$2
sp_pw=$3

# login with known credentials
az login --service-principal \
  --user "${sp_id}" \
  --password="${sp_pw}" \
  --tenant "${tenant_id}" \
  --allow-no-subscriptions \
  --output json

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
  echo "login_azcli.sh: Get the tenant ID from some MLZ configuration file and login using known Service Principal credentials"
  error_log "usage: login_azcli.sh <mlz config>"
}

if [[ "$#" -lt 1 ]]; then
   usage
   exit 1
fi

mlz_config=$1

# source the variables from MLZ config
source "${mlz_config}"

# login with known credentials
az login --service-principal \
  --user "${MLZCLIENTID}" \
  --password="${MLZCLIENTSECRET}" \
  --tenant "${mlz_tenantid}" \
  --allow-no-subscriptions \
  --output none

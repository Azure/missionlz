#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,2154
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# setup a local front end for MLZ

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "setup_ezdeploy_local.sh: setup a local front end for MLZ"
  error_log "usage: setup_ezdeploy.sh <mlz config file> <local url for front end>"
}

if [[ "$#" -lt 2 ]]; then
   usage
   exit 1
fi

mlz_config_file=$1
local_fqdn=$2

container_registry_path="$(realpath "${BASH_SOURCE%/*}")/container-registry"

# generate MLZ configuration names
. "$(realpath "${BASH_SOURCE%/*}")/config/generate_names.sh" "$mlz_config_file"

# create auth scopes
"${container_registry_path}/add_auth_scopes.sh" "$mlz_config_file" "$local_fqdn"

auth_client_id=$(az keyvault secret show \
  --name "${mlz_login_app_kv_name}" \
  --vault-name "${mlz_kv_name}" \
  --query value \
  --output tsv)
auth_client_secret=$(az keyvault secret show \
  --name "${mlz_login_app_kv_password}" \
  --vault-name "${mlz_kv_name}" \
  --query value \
  --output tsv)
mlz_client_id=$(az keyvault secret show \
  --name "${mlz_sp_kv_name}" \
  --vault-name "${mlz_kv_name}" \
  --query value \
  --output tsv)
mlz_client_secret=$(az keyvault secret show \
  --name "${mlz_sp_kv_password}" \
  --vault-name "${mlz_kv_name}" \
  --query value \
  --output tsv)

# echo out env vars
echo "INFO: Your environment variables for local execution are:"
echo "for bash:"
echo "export CLIENT_ID=$auth_client_id"
echo "export CLIENT_SECRET=$auth_client_secret"
echo "export TENANT_ID=$mlz_tenantid"
echo "export MLZ_LOCATION=$mlz_config_location"
echo "export SUBSCRIPTION_ID=$mlz_config_subid"
echo "export TF_ENV=$tf_environment"
echo "export MLZ_ENV=$mlz_env_name"
echo "export MLZCLIENTID=$mlz_client_id"
echo "export MLZCLIENTSECRET=$mlz_client_secret"
echo "for PowerShell:"
echo "\$env:CLIENT_ID='$client_id'"
echo "\$env:CLIENT_SECRET='$client_password'"
echo "\$env:TENANT_ID='$mlz_tenantid'"
echo "\$env:MLZ_LOCATION='$mlz_config_location'"
echo "\$env:SUBSCRIPTION_ID='$mlz_config_subid'"
echo "\$env:TF_ENV='$tf_environment'"
echo "\$env:MLZ_ENV='$mlz_env_name'"
echo "\$env:MLZCLIENTID='$(az keyvault secret show --name "${mlz_sp_kv_name}" --vault-name "${mlz_kv_name}" --query value --output tsv)'"
echo "\$env:MLZCLIENTSECRET='$(az keyvault secret show --name "${mlz_sp_kv_password}" --vault-name "${mlz_kv_name}" --query value --output tsv)'"
exit 0

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
  echo "deploy_ui_local.sh: setup a local front end for MLZ"
  error_log "usage: deploy_ui_local.sh <mlz config file> <local url for front end>"
}

if [[ "$#" -lt 2 ]]; then
   usage
   exit 1
fi

mlz_config_file=$1
web_port=$2

container_registry_path="$(realpath "${BASH_SOURCE%/*}")/container-registry"

# source mlz_config_file
. "${mlz_config_file}"

# generate MLZ configuration names
. "$(realpath "${BASH_SOURCE%/*}")/config/generate_names.sh" "$mlz_config_file"

# create auth scopes
local_fqdn="localhost:${web_port}"
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
echo "INFO: Complete!"
echo "=============================="
echo "INFO: 1) To run the UI first set the environment variables below"
echo "=============================="

echo "for bash:"
echo "export CLIENT_ID=$auth_client_id"
echo "export CLIENT_SECRET=$auth_client_secret"
echo "export TENANT_ID=$mlz_tenantid"
echo "export MLZ_CLOUDNAME=$mlz_cloudname"
echo "export MLZ_METADATAHOST=$mlz_metadatahost"
echo "export MLZ_ACTIVEDIRECTORY=$mlz_activeDirectory"
echo "export MLZ_KEYVAULTDNS=$mlz_keyvaultDns"
echo "export MLZ_LOCATION=$mlz_config_location"
echo "export SUBSCRIPTION_ID=$mlz_config_subid"
echo "export HUB_SUBSCRIPTION_ID=$mlz_saca_subid"
echo "export TIER0_SUBSCRIPTION_ID=$mlz_tier0_subid"
echo "export TIER1_SUBSCRIPTION_ID=$mlz_tier1_subid"
echo "export TIER2_SUBSCRIPTION_ID=$mlz_tier2_subid"
echo "export TF_ENV=$tf_environment"
echo "export MLZ_ENV=$mlz_env_name"
echo "export MLZCLIENTID=$mlz_client_id"
echo "export MLZCLIENTSECRET=$mlz_client_secret"
echo "export MLZOBJECTID=$mlz_object_id"

echo "for PowerShell:"
echo "\$env:CLIENT_ID='$auth_client_id'"
echo "\$env:CLIENT_SECRET='$auth_client_secret'"
echo "\$env:TENANT_ID='$mlz_tenantid'"
echo "\$env:MLZ_CLOUDNAME='$mlz_cloudname'"
echo "\$env:MLZ_METADATAHOST='$mlz_metadatahost'"
echo "\$env:MLZ_ACTIVEDIRECTORY='$mlz_activeDirectory'"
echo "\$env:MLZ_KEYVAULTDNS='$mlz_keyvaultDns'"
echo "\$env:MLZ_LOCATION='$mlz_config_location'"
echo "\$env:SUBSCRIPTION_ID='$mlz_config_subid'"
echo "\$env:HUB_SUBSCRIPTION_ID='HUB_SUBSCRIPTION_ID=$mlz_saca_subid'"
echo "\$env:TIER0_SUBSCRIPTION_ID='TIER0_SUBSCRIPTION_ID=$mlz_tier0_subid'"
echo "\$env:TIER1_SUBSCRIPTION_ID='TIER1_SUBSCRIPTION_ID=$mlz_tier1_subid'"
echo "\$env:TIER2_SUBSCRIPTION_ID='TIER2_SUBSCRIPTION_ID=$mlz_tier2_subid'"
echo "\$env:TF_ENV='$tf_environment'"
echo "\$env:MLZ_ENV='$mlz_env_name'"
echo "\$env:MLZCLIENTID='$(az keyvault secret show --name "${mlz_sp_kv_name}" --vault-name "${mlz_kv_name}" --query value --output tsv)'"
echo "\$env:MLZCLIENTSECRET='$(az keyvault secret show --name "${mlz_sp_kv_password}" --vault-name "${mlz_kv_name}" --query value --output tsv)'"
echo "\$env:MLZOBJECTID='$(az keyvault secret show --name "${mlz_sp_obj_name}" --vault-name "${mlz_kv_name}" --query value --output tsv)'"

echo "=============================="
echo "INFO: 2) Then, execute the web server with:"
echo "=============================="
echo "cd ../front"
echo "python3 main.py ${web_port}"
exit 0

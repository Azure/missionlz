#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC1091,2154
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC1091: Not following. Shellcheck can't follow non-constant source.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# This script deploys container registries, app registrations, and a container instance to run the MLZ front end

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "setup_ezdeploy.sh: Setup the Front End for MLZ"
  error_log "usage: setup_ezdeploy.sh -d <local|build|load> -s <subscription_id> -t <tenant_id> -l <location> -e <tf_env_name {{default=public}}> -m <mlz_env_name {{default=mlzdeployment}}> -p <web_port {{default=80}}> -0 <saca_subscription_id> -1 <tier0_subscription_id> -2 <tier1_subscription_id> -3 <tier2_subscription_id>"
}

if [[ "$#" -lt 8 ]]; then
   usage
   exit 1
fi

metadata_host="management.azure.com" # TODO (20210401): pass this by parameter or derive from cloud
acr_endpoint="azurecr.io" # TODO (20210401): pass this by parameter or derive from cloud

tf_environment=public
mlz_env_name=mlzdeployment
web_port=80
subs=()

while getopts "d:s:t:l:e:m:p:0:1:2:3:4:" opts; do
  case "${opts}" in
    d) docker_strategy=${OPTARG}
      ;;
    s) mlz_config_subid=${OPTARG}
      subs+=("${OPTARG}")
      ;;
    t) mlz_tenantid=${OPTARG}
      ;;
    l) mlz_config_location=${OPTARG}
      ;;
    e) tf_environment=${OPTARG}
      ;;
    m) mlz_env_name=${OPTARG}
      ;;
    p) web_port=${OPTARG}
      ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      exit 2
      ;;
  esac
done

this_script_path=$(realpath "${BASH_SOURCE%/*}")
src_path=$(dirname "${this_script_path}")
container_registry_path="$(realpath "${this_script_path}")/container-registry"

# check for dependencies
"${this_script_path}/util/checkforazcli.sh"
"${this_script_path}/util/checkfordocker.sh"

# check docker strategy
if [[ $docker_strategy != "local" && \
      $docker_strategy != "build" && \
      $docker_strategy != "load" ]]; then
  error_log "ERROR: Unrecognized docker strategy detected. Must be 'local', 'build', or 'load'."
  exit 1
fi

# create MLZ configuration file
mlz_config_file="${src_path}/mlz.config"
echo "INFO: creating a mlz.config file based on user input at $(realpath "$mlz_config_file")..."
"${this_script_path}/config/generate_config_file.sh" \
    "$mlz_config_file" \
    "$tf_environment" \
    "$metadata_host" \
    "$mlz_env_name" \
    "$mlz_config_location" \
    "$mlz_config_subid" \
    "$mlz_tenantid"

# generate MLZ configuration names
. "${this_script_path}/config/generate_names.sh" "$mlz_config_file"

echo "INFO: setting up required MLZ resources using $(realpath "$mlz_config_file")..."
"${this_script_path}/config/mlz_config_create.sh" "$mlz_config_file"

echo "INFO: setting current az cli subscription to ${mlz_config_subid}..."
az account set --subscription "${mlz_config_subid}"

if [[ $docker_strategy == "local" ]]; then
  local_fqdn="localhost:${web_port}"
  "${this_script_path}/setup_ezdeploy_local.sh" "$mlz_config_file" "$local_fqdn"
  exit 0
fi

# create container registry
"${container_registry_path}/create_acr.sh" "$mlz_config_file"

# build/load, tag, and push image
image_name="lzfront"
image_tag=":latest"

if [[ $docker_strategy == "build" ]]; then
  docker build -t "${image_name}" "${src_path}"
fi

if [[ $docker_strategy == "load" ]]; then
  unzip mlz.zip .
  docker load -i mlz.tar
fi

docker tag "${image_name}${image_tag}" "${mlz_acr_name}.${acr_endpoint}/${image_name}${image_tag}"
docker push "${mlz_acr_name}.${acr_endpoint}/${image_name}${image_tag}"

# deploy instance
"${container_registry_path}/deploy_instance.sh" "$mlz_config_file" "$image_name" "$image_tag"

# get URL
container_fqdn=$(az container show \
  --resource-group "${mlz_rg_name}"\
  --name "${mlz_instance_name}" \
  --query ipAddress.fqdn \
  --output tsv)

# create an app registration and add auth scopes to facilitate MSAL login
"${container_registry_path}/add_auth_scopes.sh" "$mlz_config_file" "$container_fqdn"

echo "INFO: Complete! You can access the front end at http://$container_fqdn"

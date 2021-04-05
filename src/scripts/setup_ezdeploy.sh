#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1083,SC1090,SC1091,2154
# SC1083: This is literal.
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC1091: Not following. Shellcheck can't follow non-constant source.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# This script deploys container registries, app registrations, and a container instance to run the MLZ front end

set -e

error_log() {
  echo "${1}" 1>&2;
}

show_help() {
  print_formatted() {
    long_name=$1
    char_name=$2
    desc=$3
    printf "%20s %2s %s \n" "$long_name" "$char_name" "$desc"
  }
  print_formatted "argument" "" "description"
  print_formatted "--docker-strategy" "-d" "[local|build|load] 'local' for localhost, 'build' to build from this repo, or 'load' to unzip an image (defaults to 'build')"
  print_formatted "--subscription-id" "-s" "Subscription ID for MissionLZ resources"
  print_formatted "--tenant-id" "-t" "Tenant ID where your subscriptions live"
  print_formatted "--location" "-l" "The location that you're deploying to (defaults to 'eastus')"
  print_formatted "--tf-environment" "-e" "Terraform azurerm environment (defaults to 'public') see: https://www.terraform.io/docs/language/settings/backends/azurerm.html#environment"
  print_formatted "--mlz-env-name" "-z" "Unique name for MLZ environment (defaults to 'mlz' + UNIX timestamp)"
  print_formatted "--hub-sub-id" "-h" "subscription ID for the hub network and resources (defaults to the value provided for -s --subscription-id)"
  print_formatted "--tier0-sub-id" "-0" "subscription ID for tier 0 network and resources (defaults to the value provided for -s --subscription-id)"
  print_formatted "--tier1-sub-id" "-1" "subscription ID for tier 1 network and resources (defaults to the value provided for -s --subscription-id)"
  print_formatted "--tier2-sub-id" "-2" "subscription ID for tier 2 network and resources (defaults to the value provided for -s --subscription-id)"
}

usage() {
  echo "setup_ezdeploy.sh: Setup the front end for MLZ"
  show_help
}

timestamp=$(date +%s)

metadata_host="management.azure.com" # TODO (20210401): pass this by parameter or derive from cloud
acr_endpoint="azurecr.io" # TODO (20210401): pass this by parameter or derive from cloud

# set helpful defaults that can be overridden
# or to 'notset' require mandatory input
docker_strategy="build"
mlz_config_subid="notset"
mlz_tenantid="notset"
mlz_config_location="eastus"
tf_environment="public"
mlz_env_name="mlz${timestamp}"
web_port="80"

subs=()
add_unique_sub_to_array() {
    if [[ ! "${subs[*]}" =~ ${1} ]];then
        subs+=("${1}")
    fi
}

subs_args=()

# inspect user input
while [ $# -gt 0 ] ; do
  case $1 in
    -d | --docker-strategy) docker_strategy="$2" ;;
    -s | --subscription-id) mlz_config_subid="$2" ;;
    -t | --tenant-id) mlz_tenantid="$2" ;;
    -l | --location) mlz_config_location="$2" ;;
    -e | --tf-environment) tf_environment="$2" ;;
    -z | --mlz-env-name) mlz_env_name="$2" ;;
    -p | --port) web_port="$2" ;;
    -h | --hub-sub-id)
      add_unique_sub_to_array "$2"
      subs_args+=("-h ${2}")
      ;;
    -0 | --tier0-sub-id)
      add_unique_sub_to_array "$2"
      subs_args+=("-0 ${2}")
      ;;
    -1 | --tier1-sub-id)
      add_unique_sub_to_array "$2"
      subs_args+=("-1 ${2}")
      ;;
    -2 | --tier2-sub-id)
      add_unique_sub_to_array "$2"
      subs_args+=("-2 ${2}")
      ;;
  esac
  shift
done

# check mandatory parameters
for i in { $docker_strategy $mlz_config_subid $mlz_tenantid $mlz_config_location $tf_environment $mlz_env_name $web_port }
do
  if [[ $i == "notset" ]]; then
    error_log "ERROR: Missing required arguments. These arguments are mandatory: -d, -s, -t, -l, -e, -z, -p"
    usage
    exit 1
  fi
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

# create MLZ configuration file based on user input
mlz_config_file="${src_path}/mlz_tf_cfg.var"
echo "INFO: creating a MLZ config file based on user input at $(realpath "$mlz_config_file")..."

### derive args from user input
gen_config_args=()
gen_config_args+=("-f ${mlz_config_file}")
gen_config_args+=("-e ${tf_environment}")
gen_config_args+=("-m ${metadata_host}")
gen_config_args+=("-z ${mlz_env_name}")
gen_config_args+=("-l ${mlz_config_location}")
gen_config_args+=("-s ${mlz_config_subid}")
gen_config_args+=("-t ${mlz_tenantid}")

### add hubs and spokes, if present
for j in "${subs_args[@]}"
do
  gen_config_args+=("$j")
done

### expand array into a string of space separated arguments
gen_config_args_str=$(printf '%s ' "${gen_config_args[*]}")

### create the file
# shellcheck disable=SC2086
. "${this_script_path}/config/generate_config_file.sh" $gen_config_args_str

# generate MLZ configuration names
. "${this_script_path}/config/generate_names.sh" "$mlz_config_file"

# create MLZ required resources
echo "INFO: setting up required MLZ resources using $(realpath "$mlz_config_file")..."
"${this_script_path}/config/mlz_config_create.sh" "$mlz_config_file"

# add permissions to subscriptions provided by input
mlz_sp_objid=$(az ad sp show \
  --id "http://${mlz_sp_name}" \
  --query objectId \
  --output tsv)

for sub in "${subs[@]}"
do
  echo "INFO: setting Contributor role assignment for ${mlz_sp_name} on subscription ${sub}..."
  az role assignment create \
      --role Contributor \
      --assignee-object-id "${mlz_sp_objid}" \
      --scope "/subscriptions/${sub}" \
      --assignee-principal-type ServicePrincipal \
      --only-show-errors \
      --output none
done

# switch to the MLZ subscription
echo "INFO: setting current az cli subscription to ${mlz_config_subid}..."
az account set --subscription "${mlz_config_subid}"

# if local, call setup_ezdeploy_local
if [[ $docker_strategy == "local" ]]; then
  "${this_script_path}/setup_ezdeploy_local.sh" "$mlz_config_file" "$web_port"
  exit 0
fi

# otherwise, create container registry
"${container_registry_path}/create_acr.sh" "$mlz_config_file"

# build/load, tag, and push image
image_name="lzfront"
image_tag="latest"

if [[ $docker_strategy == "build" ]]; then
  docker build -t "${image_name}" "${src_path}"
fi

if [[ $docker_strategy == "load" ]]; then
  unzip mlz.zip .
  docker load -i mlz.tar
fi

docker tag "${image_name}:${image_tag}" "${mlz_acr_name}.${acr_endpoint}/${image_name}:${image_tag}"
docker push "${mlz_acr_name}.${acr_endpoint}/${image_name}:${image_tag}"

# deploy an instance
"${container_registry_path}/deploy_instance.sh" "$mlz_config_file" "$image_name" "$image_tag"

# get the URL for the instance
container_fqdn=$(az container show \
  --resource-group "${mlz_rg_name}"\
  --name "${mlz_instance_name}" \
  --query ipAddress.fqdn \
  --output tsv)

# create an app registration and add auth scopes to facilitate MSAL login for the instance
"${container_registry_path}/add_auth_scopes.sh" "$mlz_config_file" "$container_fqdn"

echo "INFO: COMPLETE! You can access the front end at http://$container_fqdn"

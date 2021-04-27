#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=1091
# SC1091: Not following. Shellcheck can't follow non-constant source. These script are dynamically resolved.
#
# create all the configuration and deploy Terraform resources with minimal input

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
  print_formatted "--subscription-id" "-s" "Subscription ID for MissionLZ resources"
  print_formatted "--location" "-l" "[OPTIONAL] The location that you're deploying to (defaults to 'eastus')"
  print_formatted "--tf-environment" "-e" "[OPTIONAL] Terraform azurerm environment (defaults to 'public') see: https://www.terraform.io/docs/language/settings/backends/azurerm.html#environment"
  print_formatted "--mlz-env-name" "-z" "[OPTIONAL] Unique name for MLZ environment (defaults to 'mlz' + UNIX timestamp)"
  print_formatted "--hub-sub-id" "-h" "[OPTIONAL] subscription ID for the hub network and resources (defaults to the value provided for -s --subscription-id)"
  print_formatted "--tier0-sub-id" "-0" "[OPTIONAL] subscription ID for tier 0 network and resources (defaults to the value provided for -s --subscription-id)"
  print_formatted "--tier1-sub-id" "-1" "[OPTIONAL] subscription ID for tier 1 network and resources (defaults to the value provided for -s --subscription-id)"
  print_formatted "--tier2-sub-id" "-2" "[OPTIONAL] subscription ID for tier 2 network and resources (defaults to the value provided for -s --subscription-id)"
}

usage() {
  echo "deploy.sh: create all the configuration and deploy Terraform resources with minimal input"
  show_help
}

this_script_path=$(realpath "${BASH_SOURCE%/*}")
configuration_output_path="${this_script_path}/generated-configurations"
timestamp=$(date +%s)

##### check for dependencies #####

"${this_script_path}/scripts/util/checkforazcli.sh"
"${this_script_path}/scripts/util/checkforterraform.sh"

##### generate an MLZ config file #####

# set helpful defaults that can be overridden or 'notset' for mandatory input
default_config_subid="notset"
default_config_location="eastus"
default_tf_environment="public"
default_env_name="mlz${timestamp}"

mlz_config_subid="${default_config_subid}"
mlz_config_location="${default_config_location}"
tf_environment="${default_tf_environment}"
mlz_env_name="${default_env_name}"

subs_args=()

# inspect user input
while [ $# -gt 0 ] ; do
  case $1 in
    -s | --subscription-id) mlz_config_subid="$2" ;;
    -l | --location) mlz_config_location="$2" ;;
    -e | --tf-environment) tf_environment="$2" ;;
    -z | --mlz-env-name) mlz_env_name="$2" ;;
    -h | --hub-sub-id) subs_args+=("-h ${2}") ;;
    -0 | --tier0-sub-id) subs_args+=("-0 ${2}") ;;
    -1 | --tier1-sub-id) subs_args+=("-1 ${2}") ;;
    -2 | --tier2-sub-id) subs_args+=("-2 ${2}") ;;
  esac
  shift
done

# check mandatory parameters
# shellcheck disable=1083
for i in { $mlz_config_subid }
do
  if [[ $i == "notset" ]]; then
    error_log "ERROR: Missing required arguments. These arguments are mandatory: -s"
    usage
    exit 1
  fi
done

# notify the user about any defaults
notify_of_default() {
  argument_name=$1
  argument_default=$2
  argument_value=$3
  if [[ "${argument_value}" = "${argument_default}" ]]; then
    echo "INFO: using the default value '${argument_default}' for '${argument_name}', specify the '${argument_name}' argument to provide a different value."
  fi
}
notify_of_default "--location" "${default_config_location}" "${mlz_config_location}"
notify_of_default "--tf-environment" "${default_tf_environment}" "${tf_environment}"
notify_of_default "--mlz-env-name" "${default_env_name}" "${mlz_env_name}"

# switch to the MLZ subscription
echo "INFO: setting current subscription to ${mlz_config_subid}..."
az account set \
  --subscription "${mlz_config_subid}" \
  --only-show-errors \
  --output none

# validate that the location is present in the current cloud
"${this_script_path}/scripts/util/validateazlocation.sh" "${mlz_config_location}"

# validate that terraform environment matches for the current cloud
"${this_script_path}/scripts/terraform/validate_cloud_for_tf_env.sh" "${tf_environment}"

# retrieve tenant ID for the MLZ subscription
mlz_tenantid=$(az account show \
  --query "tenantId" \
  --output tsv)

# create MLZ configuration file based on user input
mlz_config_file="${configuration_output_path}/${mlz_env_name}.mlzconfig"
echo "INFO: creating an MLZ config file at ${mlz_config_file}..."

# derive args from user input
gen_config_args=()
gen_config_args+=("-f ${mlz_config_file}")
gen_config_args+=("-e ${tf_environment}")
gen_config_args+=("-z ${mlz_env_name}")
gen_config_args+=("-l ${mlz_config_location}")
gen_config_args+=("-s ${mlz_config_subid}")
gen_config_args+=("-t ${mlz_tenantid}")

# add hubs and spokes input, if present
for j in "${subs_args[@]}"
do
  gen_config_args+=("$j")
done

# expand array into a string of space separated arguments
gen_config_args_str=$(printf '%s ' "${gen_config_args[*]}")

# create the file
# do not quote args $gen_config_args_str, we intend to split
# ignoring shellcheck for word splitting because that is the desired behavior
# shellcheck disable=SC2086
"${this_script_path}/scripts/config/generate_config_file.sh" $gen_config_args_str

##### create global terraform variables based on the MLZ config #####

tfvars_filename="${mlz_env_name}.tfvars"
tfvars_path="${configuration_output_path}/${tfvars_filename}"
echo "INFO: creating terraform variables at $tfvars_path..."
"${this_script_path}/scripts/terraform/create_globals_from_config.sh" "${tfvars_path}" "${mlz_config_file}"

##### create MLZ resources #####
echo "INFO: creating MLZ resources using ${mlz_config_file}..."
"${this_script_path}/scripts/mlz_tf_setup.sh" "${mlz_config_file}"

# generate names for reference
. "${this_script_path}/scripts/config/generate_names.sh" "${mlz_config_file}"

##### apply terraform using MLZ resources #####
echo "INFO: applying Terraform using ${mlz_config_file} and ${tfvars_path}..."
"${this_script_path}/build/apply_tf.sh" \
  "${mlz_config_file}" \
  "${tfvars_path}" \
  "${tfvars_path}" \
  "${tfvars_path}" \
  "${tfvars_path}" \
  "${tfvars_path}" \
  "y"

echo "INFO: Complete!"
echo "INFO: All finished? Want to clean up?"
echo "INFO: Try this command:"
echo "INFO: ${this_script_path}/clean.sh -z ${mlz_env_name}"

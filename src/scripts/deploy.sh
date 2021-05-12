#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=1091,2155
#
# create all the configuration and deploy Terraform resources with minimal input

set -e

error_log() {
  echo "${1}" 1>&2;
}

show_help() {
  print_formatted() {
    local long_name=$1
    local char_name=$2
    local desc=$3
    printf "%20s %2s %s \n" "$long_name" "$char_name" "$desc"
  }
  print_formatted "argument" "" "description"
  print_formatted "--subscription-id" "-s" "Subscription ID for MissionLZ resources"
  print_formatted "--location" "-l" "[OPTIONAL] The location that you're deploying to (defaults to 'eastus')"
  print_formatted "--tf-environment" "-e" "[OPTIONAL] Terraform azurerm environment (defaults to 'public') see: https://www.terraform.io/docs/language/settings/backends/azurerm.html#environment"
  print_formatted "--mlz-env-name" "-z" "[OPTIONAL] Unique name for MLZ environment (defaults to 'mlz' + UNIX timestamp)"
  print_formatted "--hub-sub-id" "-u" "[OPTIONAL] subscription ID for the hub network and resources (defaults to the value provided for -s --subscription-id)"
  print_formatted "--tier0-sub-id" "-0" "[OPTIONAL] subscription ID for tier 0 network and resources (defaults to the value provided for -s --subscription-id)"
  print_formatted "--tier1-sub-id" "-1" "[OPTIONAL] subscription ID for tier 1 network and resources (defaults to the value provided for -s --subscription-id)"
  print_formatted "--tier2-sub-id" "-2" "[OPTIONAL] subscription ID for tier 2 network and resources (defaults to the value provided for -s --subscription-id)"
  print_formatted "--help" "-h" "Print this message"
}

usage() {
  echo "deploy.sh: create all the configuration and deploy Terraform resources with minimal input"
  show_help
}

check_dependencies() {
  "${this_script_path}/util/checkforazcli.sh"
  "${this_script_path}/util/checkforterraform.sh"
}

inspect_user_input() {
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
  log_default() {
    local argument_name=$1
    local argument_default=$2
    local argument_value=$3
    if [[ "${argument_value}" = "${argument_default}" ]]; then
      echo "INFO: using the default value '${argument_default}' for '${argument_name}', specify the '${argument_name}' argument to provide a different value."
    fi
  }
  log_default "--location" "${default_config_location}" "${mlz_config_location}"
  log_default "--tf-environment" "${default_tf_environment}" "${tf_environment}"
  log_default "--mlz-env-name" "${default_env_name}" "${mlz_env_name}"
}

login_azcli() {
  echo "INFO: setting current subscription to ${mlz_config_subid}..."
  az account set \
    --subscription "${mlz_config_subid}" \
    --only-show-errors \
    --output none
}

validate_cloud_arguments() {
  echo "INFO: validating settings for '${mlz_config_location}' and '${tf_environment}'..."
  # ensure location is present and terraform environment matches for the current cloud
  "${this_script_path}/util/validateazlocation.sh" "${mlz_config_location}"
  "${this_script_path}/terraform/validate_cloud_for_tf_env.sh" "${tf_environment}"
}

create_mlz_configuration_file() {
  echo "INFO: creating an MLZ config file at ${mlz_config_file_path}..."

  local mlz_tenantid=$(az account show \
    --query "tenantId" \
    --output tsv)

  local gen_config_args=()
  gen_config_args+=("-f ${mlz_config_file_path}")
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
  local gen_config_args_str=$(printf '%s ' "${gen_config_args[*]}")

  # ignoring shellcheck for word splitting because that is the desired behavior
  # shellcheck disable=SC2086
  "${this_script_path}/config/generate_config_file.sh" $gen_config_args_str
}

create_mlz_resources() {
  echo "INFO: creating MLZ resources using ${mlz_config_file_path}..."
  "${this_script_path}/config/create_mlz_configuration_resources.sh" "${mlz_config_file_path}"
}

create_terraform_variables() {
  echo "INFO: creating terraform variables at ${tfvars_file_path}..."
  "${this_script_path}/terraform/create_globals_from_config.sh" "${tfvars_file_path}" "${mlz_config_file_path}"
}

apply_terraform() {
  echo "INFO: applying Terraform using ${mlz_config_file_path} and ${tfvars_file_path}..."
  . "${this_script_path}/config/generate_names.sh" "${mlz_config_file_path}"
  "${this_script_path}/../build/apply_tf.sh" \
    "${mlz_config_file_path}" \
    "${tfvars_file_path}" \
    "${tfvars_file_path}" \
    "${tfvars_file_path}" \
    "${tfvars_file_path}" \
    "${tfvars_file_path}" \
    "y"
}

display_clean_hint() {
  echo "INFO: Try this command to clean up what was deployed:"
  echo "INFO: ${this_script_path}/clean.sh -z ${mlz_env_name}"
}

##########
# main
##########

this_script_path=$(realpath "${BASH_SOURCE%/*}")
configuration_output_path="${this_script_path}/../generated-configurations"
timestamp=$(date +%s)

# set some defaults
default_config_subid="notset"
default_config_location="eastus"
default_tf_environment="public"
default_env_name="mlz${timestamp}"

mlz_config_subid="${default_config_subid}"
mlz_config_location="${default_config_location}"
tf_environment="${default_tf_environment}"
mlz_env_name="${default_env_name}"
subs_args=()

while [ $# -gt 0 ] ; do
  case $1 in
    -s | --subscription-id)
      shift
      mlz_config_subid="$1" ;;
    -l | --location)
      shift
      mlz_config_location="$1" ;;
    -e | --tf-environment)
      shift
      tf_environment="$1" ;;
    -z | --mlz-env-name)
      shift
      mlz_env_name="$1" ;;
    -u | --hub-sub-id)
      shift
      subs_args+=("-u ${1}") ;;
    -0 | --tier0-sub-id)
      shift
      subs_args+=("-0 ${1}") ;;
    -1 | --tier1-sub-id)
      shift
      subs_args+=("-1 ${1}") ;;
    -2 | --tier2-sub-id)
      shift
      subs_args+=("-2 ${1}") ;;
    -h | --help)
      show_help
      exit 0 ;;
    *)
      error_log "ERROR: Unexpected argument: ${1}"
      usage && exit 1 ;;
  esac
  shift
done

# validate requirements
check_dependencies
inspect_user_input
login_azcli
validate_cloud_arguments

# create variables
mlz_config_file_path="${configuration_output_path}/${mlz_env_name}.mlzconfig"
tfvars_file_path="${configuration_output_path}/${mlz_env_name}.tfvars"
create_mlz_configuration_file
create_terraform_variables

# create resources
trap 'display_clean_hint' EXIT # no matter if the next commands fail, run display_clean_hint
create_mlz_resources
apply_terraform

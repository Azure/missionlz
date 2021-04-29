#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=1083,1090,2154
#
# Generate a configuration file for MLZ prerequisites and optional SACA and T0-T2 subscriptions.

set -e

error_log() {
  echo "${1}" 1>&2;
}

show_help() {
  print_formatted() {
    long_name=$1
    char_name=$2
    desc=$3
    printf "%15s %2s %s \n" "$long_name" "$char_name" "$desc"
  }
  print_formatted "argument" "" "description"
  print_formatted "--file" "-f" "the destination file path and name (e.g. 'src/mlz_tf_cfg.var')"
  print_formatted "--tf-env" "-e" "Terraform azurerm environment (e.g. 'public') see: https://www.terraform.io/docs/language/settings/backends/azurerm.html#environment"
  print_formatted "--mlz-env-name" "-z" "Unique name for MLZ environment"
  print_formatted "--location" "-l" "The location that you're deploying to (e.g. 'eastus')"
  print_formatted "--config-sub-id" "-s" "Subscription ID for MissionLZ configuration resources"
  print_formatted "--tenant-id" "-t" "Tenant ID where your subscriptions live"
  print_formatted "--hub-sub-id" "-u" "[OPTIONAL]: subscription ID for the hub network and resources"
  print_formatted "--tier0-sub-id" "-0" "[OPTIONAL]: subscription ID for tier 0 network and resources"
  print_formatted "--tier1-sub-id" "-1" "[OPTIONAL]: subscription ID for tier 1 network and resources"
  print_formatted "--tier2-sub-id" "-2" "[OPTIONAL]: subscription ID for tier 2 network and resources"
  print_formatted "--help" "-h" "Print this message"
}

usage() {
  echo "generate_config_file.sh: Generate a configuration file for MLZ prerequisites and optional SACA and T0-T2 subscriptions"
  show_help
}

# stage required parameters as not set
dest_file="notset"
tf_environment="notset"
mlz_env_name="notset"
mlz_config_location="notset"
mlz_config_subid="notset"
mlz_tenant_id="notset"

# inspect arguments
while [ $# -gt 0 ] ; do
  case $1 in
    -f | --file)
      shift
      dest_file="$1" ;;
    -e | --tf-env)
      shift
      tf_environment="$1" ;;
    -z | --mlz-env-name)
      shift
      mlz_env_name="$1" ;;
    -l | --location)
      shift
      mlz_config_location="$1" ;;
    -s | --config-sub-id)
      shift
      mlz_config_subid="$1" ;;
    -t | --tenant-id)
      shift
      mlz_tenant_id="$1" ;;
    -u | --hub-sub-id)
      shift
      mlz_saca_subid="$1" ;;
    -0 | --tier0-sub-id)
      shift
      mlz_tier0_subid="$1" ;;
    -1 | --tier1-sub-id)
      shift
      mlz_tier1_subid="$1" ;;
    -2 | --tier2-sub-id)
      shift
      mlz_tier2_subid="$1" ;;
    -h | --help)
      show_help
      exit 0 ;;
    *)
      error_log "ERROR: Unexpected argument: ${1}"
      usage && exit 1 ;;
  esac
  shift
done

# check mandatory parameters
for i in { $dest_file $tf_environment $mlz_env_name $mlz_config_location $mlz_config_subid $mlz_tenant_id }
do
  if [[ $i == "notset" ]]; then
    error_log "ERROR: Missing required arguments. These arguments are mandatory: -f, -e, -z, -l, -s, -t"
    usage
    exit 1
  fi
done

# write the file to the desired path
rm -f "$dest_file"
dest_file_dir=$(dirname "${dest_file}")
mkdir -p "${dest_file_dir}"
touch "$dest_file"
{
  echo "tf_environment=${tf_environment}"
  echo "mlz_env_name=${mlz_env_name}"
  echo "mlz_config_location=${mlz_config_location}"
  echo "mlz_config_subid=${mlz_config_subid}"
  echo "mlz_tenantid=${mlz_tenant_id}"
} >> "$dest_file"

# for any optional parameters, check if they're set before appending them to the file
append_optional_args() {
  key_name=$1
  key_value=$2
  default_value=$3
  file_to_append=$4
  if [[ $key_value ]]; then
    printf "%s=%s\n" "${key_name}" "${key_value}" >> "${file_to_append}"
  else
    printf "%s=%s\n" "${key_name}" "${default_value}" >> "${file_to_append}"
  fi
}
append_optional_args "mlz_saca_subid" "${mlz_saca_subid}" "${mlz_config_subid}" "${dest_file}"
append_optional_args "mlz_tier0_subid" "${mlz_tier0_subid}" "${mlz_config_subid}" "${dest_file}"
append_optional_args "mlz_tier1_subid" "${mlz_tier1_subid}" "${mlz_config_subid}" "${dest_file}"
append_optional_args "mlz_tier2_subid" "${mlz_tier2_subid}" "${mlz_config_subid}" "${dest_file}"

# append cloud specific endpoints
this_script_path=$(realpath "${BASH_SOURCE%/*}")
. "${this_script_path}/append_prereq_endpoints.sh" "${dest_file}"

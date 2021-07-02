#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=1090,1091,2154
#
# remove resources deployed by deploy.sh by mlz env name

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
  print_formatted "--mlz-env-name" "-z" "Unique name for MLZ environment"
  print_formatted "--help" "-h" "Print this message"
}

usage() {
  echo "clean.sh: remove resources deployed by deploy.sh by mlz env name"
  show_help
}

check_dependencies() {
  "${this_script_path}/util/checkforazcli.sh"
  "${this_script_path}/util/checkforterraform.sh"
}

inspect_user_input() {
  # check mandatory parameters
  # shellcheck disable=1083
  for i in { $mlz_env_name }
  do
    if [[ $i == "notset" ]]; then
      error_log "ERROR: Missing required arguments. These arguments are mandatory: -z"
      usage
      exit 1
    fi
  done
}

import_configuration() {
  . "${mlz_config_file_path}"
  . "${this_script_path}/config/generate_names.sh" "${mlz_config_file_path}"
}

login_azcli() {
  echo "INFO: setting current subscription to ${mlz_config_subid}..."
  az account set \
    --subscription "${mlz_config_subid}" \
    --only-show-errors \
    --output none
}

destroy_terraform() {
  echo "INFO: destroying Terraform using ${mlz_config_file_path} and ${tfvars_file_path}..."
  "${this_script_path}/../build/destroy_tf.sh" \
  "${mlz_config_file_path}" \
  "${tfvars_file_path}" \
  "y"
}

notify_failed_to_destroy_terraform() {
  error_log "ERROR: failed to destroy Terraform deployment..."
  echo "INFO: continuing to destroy MLZ Configuration resources..."
}

destroy_mlz() {
  echo "INFO: cleaning up MLZ Configuration resources with tag 'DeploymentName=${mlz_env_name}'..."

  # clean up MLZ config resources
  . "${this_script_path}/config/config_clean.sh" "${mlz_config_file_path}"

  delete_files_in_directory_by_name() {
    directory_to_search=$1
    file_name_to_match=$2

    matches=$(find "$directory_to_search" -type f -name "$file_name_to_match")

    for match in $matches
    do
      echo "INFO: deleting $match ..."
      rm -f "$match"
    done
  }

  # clean up files
  delete_files_in_directory_by_name "${src_path}" "${tfvars_file_name}"
  echo "INFO: deleting ${configuration_output_path}/${mlz_env_name}.mlzconfig ..."
  rm -rf "${configuration_output_path}/${mlz_env_name}.mlzconfig"
  echo "INFO: deleting ${tf_mlz_main_path}/config.vars ..."
  rm -rf "${tf_mlz_main_path}/config.vars"
  echo "INFO: deleting terraform.lock file and .terraform folder ..."
  rm -rf "${tf_mlz_main_path}/.terraform.lock.hcl"
  rm -rf "${tf_mlz_main_path}/.terraform"
}

##########
# main
##########

this_script_path=$(realpath "${BASH_SOURCE%/*}")
src_path="$(realpath "${this_script_path}/../")"
configuration_output_path=$(realpath "${this_script_path}/../generated-configurations")

mlz_env_name="notset"

while [ $# -gt 0 ] ; do
  case $1 in
    -z | --mlz-env-name)
      shift
      mlz_env_name="$1" ;;
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
inspect_user_input
check_dependencies

# set paths
mlz_config_file_path="${configuration_output_path}/${mlz_env_name}.mlzconfig"
tfvars_file_name="${mlz_env_name}.tfvars"
tfvars_file_path="${configuration_output_path}/${tfvars_file_name}"
tf_mlz_main_path=$(realpath "${configuration_output_path}/../terraform/mlz")

# teardown resources
# if terraform destroy fails, notify and continue to destroy mlz
import_configuration
login_azcli
destroy_terraform || notify_failed_to_destroy_terraform
destroy_mlz

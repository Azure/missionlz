#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC2154
# SC1090: Can't follow non-constant source. These values come from an external file.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# Automation that calls destroy terraform given a MLZ configuration

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "destroy_tf.sh: Automation that calls destroy terraform given a MLZ configuration and some tfvars"
  error_log "usage: destroy_tf.sh <mlz config> <mlz.tfvars> <display terraform output (y/n)>"
}

if [[ "$#" -lt 2 ]]; then
   usage
   exit 1
fi

# take some valid, well known, mlz_config and tfvars as input
mlz_config=$(realpath "${1}")
mlz_tfvars=$(realpath "${2}")
display_tf_output=${3:-n}

# reference paths
this_script_path=$(realpath "${BASH_SOURCE%/*}")
src_dir=$(dirname "${this_script_path}")
terraform_dir="${src_dir}/terraform/"
scripts_dir="${src_dir}/scripts/"

# destroy function
destroy() {
  sub_id=$1
  tf_dir=$2
  vars=$3

  # generate config.vars based on MLZ Config and Terraform module
  . "${scripts_dir}/config/generate_vars.sh" \
      "${mlz_config}" \
      "${sub_id}" \
      "${tf_dir}"

  # remove any existing terraform initialzation
  rm -rf "${path}/.terraform"

  # copy input vars to temporary file
  input_vars=$(realpath "${vars}")
  temp_vars="temp_vars.tfvars"
  rm -f "${temp_vars}"
  touch "${temp_vars}"
  cp "${input_vars}" "${temp_vars}"

  # remove any configuration tfvars and subtitute it with input vars
  tf_vars="${tf_dir}/$(basename "${vars}")"
  rm -f "${tf_vars}"
  touch "${tf_vars}"
  cp "${temp_vars}" "${tf_vars}"
  rm -f "${temp_vars}"

  # set the target subscription
  az account set \
    --subscription "${sub_id}" \
    --output none

  # attempt to apply $max_attempts times before giving up
  # (race conditions, transient errors etc.)
  destroy_success="false"
  attempts=1
  max_attempts=1

  destroy_command="${scripts_dir}/terraform/destroy_terraform.sh ${tf_dir} ${tf_vars} y"

  if [[ "$display_tf_output" == "n" ]]; then
    destroy_command+=" &>/dev/null"
  fi

  while [ $destroy_success == "false" ]
  do
    echo "INFO: destroying ${tf_dir} (${attempts}/${max_attempts})..."

    if ! eval "$destroy_command";
    then
      # if we fail, run terraform destroy again until $max_attempts
      error_log "ERROR: failed to destroy ${tf_dir} (${attempts}/${max_attempts})"

      ((attempts++))

      if [[ $attempts -gt $max_attempts ]]; then
        error_log "ERROR: failed ${max_attempts} times to destroy ${tf_dir}. Exiting."
        exit 1
      fi
    else
      destroy_success="true"
      echo "INFO: finished destroying ${tf_dir}!"
    fi
  done
}

# source vars from mlz_config
. "${mlz_config}"

# call destroy()
destroy "${mlz_saca_subid}" "${terraform_dir}/mlz" "${mlz_tfvars}"

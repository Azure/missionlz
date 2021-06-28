#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC2154
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# Deployment script for performing all of the required steps to deploy and bind a tier3 to an existing MLZ deployment

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "deploy_t3.sh: Automation that calls apply terraform given a MLZ configuration and some tfvars"
  error_log "usage: deploy_t3.sh <mlz config> <globals.tfvars> <output.tfvars> <tier3.tfvars> <display terraform output (y/n)>"
}

if [[ "$#" -lt 3 ]]; then
   usage
   exit 1
fi

# take some valid, well known, mlz_config and vars as input
mlz_config=$1
globals=$2
output=$3
pre_tier3_vars=$4
display_tf_output=${5:-n}

# reference paths
this_script_path=$(realpath "${BASH_SOURCE%/*}")
configuration_output_path="${this_script_path}/../generated-configurations"
merged_output_name="merged_vars.tfvars"
src_dir=$(dirname "${this_script_path}")
terraform_path="${src_dir}/terraform/"
scripts_dir="${src_dir}/scripts/"

# Merge outputs and tier3 files to send to tier3 deployment
cat ${output} ${pre_tier3_vars} > ${configuration_output_path}/${merged_output_name}

# apply function
apply() {
  sub_id=$1
  tf_dir=$2
  vars=$3

  # generate config.vars based on MLZ Config and Terraform module
  . "${scripts_dir}/config/generate_vars.sh" \
      "${mlz_config}" \
      "${sub_id}" \
      "${tf_dir}"

  # remove any existing terraform initialzation
  rm -rf "${tf_dir}/.terraform"

  # copy input vars to temporary file
  input_vars=$(realpath "${vars}")
  temp_vars="temp_vars.tfvars"
  rm -f "${temp_vars}"
  touch "${temp_vars}"
  cp "${input_vars}" "${temp_vars}"

  # remove any tfvars and subtitute it with input vars
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
  apply_success="false"
  attempts=1
  max_attempts=5

  apply_command="${scripts_dir}/terraform/apply_terraform.sh ${tf_dir} ${tf_vars} y"
  destroy_command="${scripts_dir}/terraform/destroy_terraform.sh ${tf_dir} ${tf_vars} y"

  if [[ $display_tf_output == "n" ]]; then
    apply_command+=" &>/dev/null"
    destroy_command+=" &>/dev/null"
  fi

  while [ $apply_success == "false" ]
  do
    echo "INFO: applying Terraform at ${tf_dir} (${attempts}/${max_attempts})..."

    if ! eval "$apply_command";
    then
      # if we fail, run terraform destroy and try again
      error_log "ERROR: failed to apply ${tf_dir} (${attempts}/${max_attempts}). Trying some manual clean-up and Terraform destroy..."
      eval "$destroy_command"

      ((attempts++))

      if [[ $attempts -gt $max_attempts ]]; then
        error_log "ERROR: failed ${max_attempts} times to apply ${tf_dir}. Exiting."
        exit 1
      fi
    else
      # if we succeed meet the base case
      apply_success="true"
      echo "INFO: finished applying ${tf_dir}!"
    fi
  done
}

# source vars from mlz_config
. "${mlz_config}"

# call apply()
apply "${mlz_tier3_subid}" "${terraform_path}/tier3" "${configuration_output_path}/${merged_output_name}"

#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC2154
# SC1090: Can't follow non-constant source. These values come from an external file.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# Automation that calls destroy terraform given a MLZ configuration and some globals.tfvars

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "destroy_tf.sh: Automation that calls destroy terraform given a MLZ configuration and some tfvars"
  error_log "usage: destroy_tf.sh <mlz config> <globals.tfvars> <saca.tfvars> <tier0.tfvars> <tier1.tfvars> <tier2.tfvars> <display terraform output (y/n)>"
}

if [[ "$#" -lt 6 ]]; then
   usage
   exit 1
fi

# take some valid, well known, mlz_config and vars as input
mlz_config=$1
globals=$2
saca_vars=$3
tier0_vars=$4
tier1_vars=$5
tier2_vars=$6
display_tf_output=${7:-n}

# reference paths
this_script_path=$(realpath "${BASH_SOURCE%/*}")
src_dir=$(dirname "${this_script_path}")
core_path="${src_dir}/core/"
scripts_path="${src_dir}/scripts/"

# destroy function
destroy() {
  name=$1
  tier_sub=$2
  path=$3
  vars=$4

  # generate config.vars based on MLZ Config and Terraform module
  . "${scripts_path}/config/generate_vars.sh" \
      "${mlz_config}" \
      "${tier_sub}" \
      "${name}" \
      "${path}"

  # remove any existing terraform initialzation
  rm -rf "${path}/.terraform"

  # copy input vars to temporary file
  input_vars=$(realpath "${vars}")
  temp_vars="temp_vars.tfvars"
  rm -f "${temp_vars}"
  touch "${temp_vars}"
  cp "${input_vars}" "${temp_vars}"

  # remove any configuration tfvars and subtitute it with input vars
  tf_vars="${path}/$(basename "${vars}")"
  rm -f "${tf_vars}"
  touch "${tf_vars}"
  cp "${temp_vars}" "${tf_vars}"
  rm -f "${temp_vars}"

  # set the target subscription
  az account set \
    --subscription "${tier_sub}" \
    --output none

  # attempt to destroy $max_attempts times before giving up waiting $sleep_seconds between attempts
  # (race conditions, transient errors etc.)
  destroy_success="false"
  attempts=1
  max_attempts=5

  destroy_command="${scripts_path}/terraform/destroy_terraform.sh ${globals} ${path} ${tf_vars} y"

  if [[ "$display_tf_output" == "n" ]]; then
    destroy_command+=" &>/dev/null"
  fi

  while [ $destroy_success == "false" ]
  do
    echo "INFO: destroying ${name} (${attempts}/${max_attempts})..."

    if ! eval "$destroy_command";
    then
      # if we fail, run terraform destroy again until $max_attempts
      error_log "ERROR: failed to destroy ${name} (${attempts}/${max_attempts})"

      ((attempts++))

      if [[ $attempts -gt $max_attempts ]]; then
        error_log "ERROR: failed ${max_attempts} times to destroy ${name}. Exiting."
        exit 1
      fi
    else
      destroy_success="true"
      echo "INFO: finished destroying ${name}!"
    fi
  done
}

# source vars from mlz_config
. "${mlz_config}"

# call destroy()
destroy "tier-2" "${mlz_tier2_subid}" "${core_path}/tier-2" "${tier2_vars}"
destroy "tier-1" "${mlz_tier1_subid}" "${core_path}/tier-1" "${tier1_vars}"
destroy "tier-0" "${mlz_tier0_subid}" "${core_path}/tier-0" "${tier0_vars}"
destroy "saca-hub" "${mlz_saca_subid}" "${core_path}/saca-hub" "${saca_vars}"

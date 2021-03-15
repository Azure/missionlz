#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC2154
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# Automation that calls destroy terraform given a MLZ configuration and some globals.tfvars

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "destroy_tf.sh: Automation that calls destroy terraform given a MLZ configuration and some tfvars"
  error_log "usage: destroy_tf.sh <mlz config> <globals.tfvars> <saca.tfvars> <tier0.tfvars> <tier1.tfvars> <tier2.tfvars> <silently execute terraform (y/n)>"
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
silent_tf=${7:-n}

# reference paths
core_path=$(realpath ../src/core/)
scripts_path=$(realpath ../scripts/)

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

  # remove any tfvars and subtitute it
  tf_vars="${path}/${name}.tfvars"
  rm -rf "${tf_vars}"
  cp "${vars}" "${tf_vars}"

  # set the target subscription
  az account set \
    -s "${tier_sub}" \
    -o none

  # destroy terraform
  destroy_log="mlz_tf_apply.log"
  destroy_command="${scripts_path}/destroy_terraform.sh ${globals} ${path} y"

  # if silent, output to /dev/null
  if [[ "$silent_tf" == "y" ]]; then
    destroy_command+=" 1> /dev/null"
  fi

  # attempt to apply $max_attempts times before giving up
  # (race conditions, transient errors etc.)
  attempts=1
  max_attempts=5

  while [ $attempts -le $max_attempts ]
  do
    rm -f "${destroy_log}"
    touch "${destroy_log}"

    # if we fail somehow, try to delete the diagnostic logs
    if ! $destroy_command 2> $destroy_log; then

      error_log "Failed to destroy ${name} (${attempts}/${max_attempts}). Trying again..."
      ((attempts++))

      # if we failed $max_attempts times, give up
      if [[ $attempts -gt $max_attempts ]]; then
        error_log "Failed ${max_attempts} times to apply ${name}. Exiting."
        exit 1
      fi

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

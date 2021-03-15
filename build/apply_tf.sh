#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC2154
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# Automation that calls apply terraform given a MLZ configuration and some globals.tfvars

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "apply_tf.sh: Automation that calls apply terraform given a MLZ configuration and some tfvars"
  error_log "usage: apply_tf.sh <mlz config> <globals.tfvars> <saca.tfvars> <tier0.tfvars> <tier1.tfvars> <tier2.tfvars> <silently execute terraform (y/n)>"
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

# TODO (20210315):
# 1. there's a race condition in either our Terraform, or in the azurerm provider we're using
#    where diagnostic log settings are deleted before they're purged from state or vice/versa
# 2. this method scans a Terraform apply log file for instances of these failures and deletes them
# 3. see: https://github.com/terraform-providers/terraform-provider-azurerm/issues/8109
delete_diagnostic_conflicts() {
  apply_log_file=$1
  sleep_time_in_seconds=$2

  # inspect the apply log for a diagnostic setting conflict, delete it manually
  while read -r line
  do
      diagnostic_target=$(echo "${line}" | sed -nE 's|.*ID "(.*)/providers/microsoft.insights/diagnosticSettings.* already.*azurerm_monitor_diagnostic_setting.*$|\1|p')
      diagnostic_name=$(echo "${line}" | sed -nE 's|.*ID ".*/diagnosticSettings/(.*)" already.*azurerm_monitor_diagnostic_setting.*$|\1|p')

      if [[ -n "$diagnostic_target" ]]; then
          az monitor diagnostic-settings delete \
            --name "${diagnostic_name}" \
            --resource "${diagnostic_target}" \
            --output none \
            --only-show-errors

          echo "Waiting $sleep_time_in_seconds seconds for deletion of ${diagnostic_name} to propogate..."
          sleep "${sleep_time_in_seconds}"
      fi
  done < $apply_log_file
}

# apply function
apply() {
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

  # apply terraform
  apply_log="mlz_tf_apply.log"
  apply_command="${scripts_path}/apply_terraform.sh ${globals} ${path} y"

  # if silent, output to /dev/null
  if [[ "$silent_tf" == "y" ]]; then
    apply_command+=" 1> /dev/null"
  fi

  # attempt to apply $max_attempts times before giving up waiting $sleep_seconds between attempts
  # (race conditions, transient errors etc.)
  attempts=1
  max_attempts=5
  sleep_seconds=60

  while [ $attempts -le $max_attempts ]
  do
    rm -f "${apply_log}"
    touch "${apply_log}"

    # if we fail somehow, try to delete the diagnostic logs
    if ! $apply_command 2> $apply_log; then

      error_log "Failed to apply ${name} (${attempts}/${max_attempts}). Trying some manual clean-up..."
      delete_diagnostic_conflicts $apply_log $sleep_seconds

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

# call apply()
apply "saca-hub" "${mlz_saca_subid}" "${core_path}/saca-hub" "${saca_vars}"
apply "tier-0" "${mlz_tier0_subid}" "${core_path}/tier-0" "${tier0_vars}"
apply "tier-1" "${mlz_tier1_subid}" "${core_path}/tier-1" "${tier1_vars}"
apply "tier-2" "${mlz_tier2_subid}" "${core_path}/tier-2" "${tier2_vars}"

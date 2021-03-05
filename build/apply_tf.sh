#!/bin/bash
#
# Automation that calls apply terraform given a MLZ configuration and some globals.tfvars

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "apply_tf.sh: Automation that calls apply terraform given a MLZ configuration and some tfvars"
  error_log "usage: apply_tf.sh <mlz config> <globals.tfvars> <saca.tfvars> <tier0.tfvars> <tier1.tfvars> <tier2.tfvars>"
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

# reference paths
core_path=$(realpath ../src/core/)
scripts_path=$(realpath ../scripts/)

# source vars from mlz_config
. "${mlz_config}"

# apply function
apply() {
  name=$1
  path=$2
  vars=$3

  . "${scripts_path}/config/generate_vars.sh" \
      "${mlz_config}" \
      "${mlz_config_subid}" \
      "${name}" "${path}" \
      || exit

  # remove any existing terraform initialzation
  rm -rf "${path}/.terraform"

  # remove any tfvars and subtitute it
  tf_vars="${path}/${name}.tfvars"
  rm -rf "${tf_vars}"
  cp "${3}" "${tf_vars}"

  "${scripts_path}"/apply_terraform.sh "${globals}" "${path}" || exit
}

# apply terraform
apply "saca-hub" "${core_path}/saca-hub" "${saca_vars}"
apply "tier-0" "${core_path}/tier-0" "${tier0_vars}"
apply "tier-1" "${core_path}/tier-1" "${tier1_vars}"
apply "tier-2" "${core_path}/tier-2" "${tier2_vars}"

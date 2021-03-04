#!/bin/bash
#
# Automation that calls apply terraform given a MLZ configuration and some globals.tfvars

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "apply_tf.sh: Automation that calls apply terraform given a MLZ configuration and some globals.tfvars"
  error_log "usage: apply_tf.sh <path to a mlz config> <path to a globals.tfvars>"
}

if [[ "$#" -lt 2 ]]; then
   usage
   exit 1
fi

# take some valid, well known, mlz_config and global_vars from as input
mlz_config=$1
globals=$2

# reference paths
core_path=$(realpath ../src/core/)
scripts_path=$(realpath ../scripts/)

# source vars from mlz_config
. "${mlz_config}"

# apply function
apply() {
  name=$1
  path=$2
  . "${scripts_path}/config/generate_vars.sh" "${mlz_config}" "${mlz_config_subid}" "${name}"
  touch "${path}/dummy.tfvars"
  "${scripts_path}"/apply_terraform.sh "${globals}" "${path}"
}

# apply terraform
apply "tier-2" "${core_path}/tier-2"
apply "tier-1" "${core_path}/tier-1"
apply "tier-0" "${core_path}/tier-0"
apply "saca-hub" "${core_path}/saca-hub"

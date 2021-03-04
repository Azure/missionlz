#!/bin/bash
#
# Automation that calls destroy terraform given a MLZ configuration and some globals.tfvars

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "destroy_tf.sh: Automation that calls destroy terraform given a MLZ configuration and some globals.tfvars"
  error_log "usage: destroy_tf.sh <path to a mlz config> <path to a globals.tfvars>"
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

# destroy function
destroy() {
  name=$1
  path=$2
  . "${scripts_path}/config/generate_vars.sh" "${mlz_config}" "${mlz_config_subid}" "${name}"
  touch "${path}/dummy.tfvars"
  "${scripts_path}"/destroy_terraform.sh "${globals}" "${path}"
}

# destroy terraform
destroy "tier-2" "${core_path}/tier-2"
destroy "tier-1" "${core_path}/tier-1"
destroy "tier-0" "${core_path}/tier-0"
destroy "saca-hub" "${core_path}/saca-hub"

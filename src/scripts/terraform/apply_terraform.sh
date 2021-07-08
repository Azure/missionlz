#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC1091,SC2154,SC2143
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC1091: Not following. Shellcheck can't follow non-constant source.
# SC2154: "var is referenced but not assigned". These values come from an external file.
# SC2143: Use grep -q instead of comparing output. Ignored for legibility.
#
# Applies a Terraform configuration given a backend configuration, a global variables file, and a terraform configurationd directory

set -e

if [[ "$#" -lt 2 ]]; then
   echo "apply_terraform.sh: initializes Terraform for a given directory using given a .env file for backend configuration"
   echo "usage: apply_terraform.sh <terraform configuration directory> <tfvars_file> <auto approve (y/n)> <extra_vars_file>"
   exit 1
fi

tf_dir=$(realpath "${1}")
tf_vars=$(realpath "${2}")
auto_approve=${3:-n}
extra_vars=${4:-notset}

scripts_path=$(realpath "${BASH_SOURCE%/*}/..")

# init terraform for the directory
. "${scripts_path}/terraform/init_terraform.sh" "$tf_dir"

# verify Service Principal is valid and set client_id, client_secret, object_id
. "${scripts_path}/config/get_sp_identity.sh" "${config_vars}"

apply_command="terraform apply"

if [[ $auto_approve == "y" ]]; then
   apply_command+=" -input=false -auto-approve"
fi

apply_command+=" -var-file=${tf_vars}"
apply_command+=" -var mlz_clientid=${client_id}"
apply_command+=" -var mlz_clientsecret=${client_secret}"
apply_command+=" -var mlz_objectid=${object_id}"

if [[ $extra_vars != "notset" ]]; then
   extra_vars_real=$(realpath "${4}")
   apply_command+=" -var-file=${extra_vars_real}"
fi

eval "${apply_command}"

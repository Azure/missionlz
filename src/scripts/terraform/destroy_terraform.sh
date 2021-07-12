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
# Destroys a Terraform configuration given a backend configuration, a global variables file, and a terraform configurationd directory

set -e

if [[ "$#" -lt 2 ]]; then
   echo "destroy_terraform.sh: initializes Terraform for a given directory using given a .env file for backend configuration"
   echo "usage: destroy_terraform.sh <terraform configuration directory> <tfvars_file> <auto approve (y/n)>"
   exit 1
fi

tf_dir=$(realpath "${1}")
tf_vars=$(realpath "${2}")
auto_approve=${3:-n}

scripts_path=$(realpath "${BASH_SOURCE%/*}/..")

# init terraform for the directory
. "${scripts_path}/terraform/init_terraform.sh" "$tf_dir"

# verify Service Principal is valid and set client_id, client_secret, object_id
. "${scripts_path}/config/get_sp_identity.sh" "${config_vars}"

# destroy the terraform configuration with global vars and the configuration's tfvars
destroy_command="terraform destroy"

if [[ $auto_approve == "y" ]]; then
   destroy_command+=" -input=false -auto-approve"
fi

destroy_command+=" -var-file=${tf_vars}"
destroy_command+=" -var mlz_clientid=${client_id}"
destroy_command+=" -var mlz_clientsecret=${client_secret}"
destroy_command+=" -var mlz_objectid=${object_id}"

eval "${destroy_command}"

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
   echo "usage: apply_terraform.sh <global variables file> <terraform configuration directory> <var_file> <auto approve (y/n)>"
   exit 1
fi

globalvars=$(realpath "${1}")
tf_dir=$(realpath "${2}")
tf_name=$(basename "${3}")
config_vars="${tf_dir}/config.vars"
tfvars="${tf_dir}/${tf_name}"

auto_approve=${4:-n}

scripts_path=$(realpath "${BASH_SOURCE%/*}/..")

# check for dependencies
. "${scripts_path}/util/checkforazcli.sh"
. "${scripts_path}/util/checkforterraform.sh"

# Validate necessary Azure resources exist
. "${scripts_path}/config/config_validate.sh" "${tf_dir}"

# Validate configuration file exists
. "${scripts_path}/util/checkforfile.sh" \
   "${config_vars}" \
   "The configuration file ${config_vars} is empty or does not exist. You may need to run MLZ setup."

# Source configuration file
. "${config_vars}"

# Verify Service Principal is valid and set client_id and client_secret environment variables
. "${scripts_path}/config/get_sp_identity.sh" "${config_vars}"

# Set the terraform state key
key="${mlz_env_name}${tf_name}"

# initialize terraform in the configuration directory
cd "${tf_dir}" || exit
terraform init \
   -backend-config "metadata_host=${metadata_host}" \
   -backend-config "key=${key}" \
   -backend-config "resource_group_name=${tf_be_rg_name}" \
   -backend-config "storage_account_name=${tf_be_sa_name}" \
   -backend-config "container_name=${container_name}" \
   -backend-config "environment=${environment}" \
   -backend-config "tenant_id=${tenant_id}" \
   -backend-config "subscription_id=${sub_id}" \
   -backend-config "client_id=${client_id}" \
   -backend-config "client_secret=${client_secret}"

# apply the terraform configuration with global vars and the configuration's tfvars
apply_command="terraform apply"

if [[ $auto_approve == "y" ]]; then
   apply_command+=" -input=false -auto-approve"
fi

apply_command+=" -var-file=${globalvars}"
apply_command+=" -var-file=${tfvars}"
apply_command+=" -var mlz_clientid=${client_id}"
apply_command+=" -var mlz_clientsecret=${client_secret}"
apply_command+=" -var mlz_objectid=${object_id}"

eval "${apply_command}"

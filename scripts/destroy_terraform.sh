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

PGM=$(basename "${0}")

if [[ "$#" -lt 2 ]]; then
   echo "destroy_terraform.sh: initializes Terraform for a given directory using given a .env file for backend configuration"
   echo "usage: destroy_terraform.sh <global variables file> <terraform configuration directory> <auto approve (y/n)>"
   exit 1
fi

globalvars=$(realpath "${1}")

tf_dir=$(realpath "${2}")
tf_name=$(basename "${tf_dir}")

config_vars="${tf_dir}/config.vars"
tfvars="${tf_dir}/${tf_name}.tfvars"

auto_approve=${3:-n}

plugin_dir="$(dirname "$(dirname "$(realpath "$0")")")/src/provider_cache"

# check for dependencies
. "${BASH_SOURCE%/*}/util/checkforazcli.sh"
. "${BASH_SOURCE%/*}/util/checkforterraform.sh"

# Validate necessary Azure resources exist
. "${BASH_SOURCE%/*}/config/config_validate.sh" "${tf_dir}"

# Get the .tfvars file matching the terraform directory name
if [[ ! -f "${tfvars}" ]]
then
    echo "${PGM}: Could not find a terraform variables file with the name '${tfvars}' at ${tf_dir}"
    echo "${PGM}: Exiting."
    exit 1
fi

# Validate configuration file exists
. "${BASH_SOURCE%/*}/util/checkforfile.sh" \
   "${config_vars}" \
   "The configuration file ${config_vars} is empty or does not exist. You may need to run MLZ setup."

# Source configuration file
. "${config_vars}"

# Verify Service Principal is valid and set client_id and client_secret environment variables
. "${BASH_SOURCE%/*}/config/get_sp_identity.sh" "${config_vars}"

# Set the terraform state key
key="${mlz_env_name}${tf_name}"

# initialize terraform in the configuration directory
cd "${tf_dir}" || exit
terraform init \
   -plugin-dir="${plugin_dir}" \
   -backend-config "key=${key}" \
   -backend-config "resource_group_name=${tf_be_rg_name}" \
   -backend-config "storage_account_name=${tf_be_sa_name}" \
   -backend-config "container_name=${container_name}" \
   -backend-config "environment=${environment}" \
   -backend-config "tenant_id=${tenant_id}" \
   -backend-config "subscription_id=${sub_id}" \
   -backend-config "client_id=${client_id}" \
   -backend-config "client_secret=${client_secret}"

# destroy the terraform configuration with global vars and the configuration's tfvars
destroy_command="terraform destroy"

if [[ $auto_approve == "y" ]]; then
   destroy_command+=" -input=false -auto-approve"
fi

destroy_command+=" -var-file=${globalvars}"
destroy_command+=" -var-file=${tfvars}"
destroy_command+=" -var mlz_clientid=${client_id}"
destroy_command+=" -var mlz_clientsecret=${client_secret}"

eval "${destroy_command}"

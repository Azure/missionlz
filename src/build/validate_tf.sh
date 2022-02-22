#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Validates and lints Terraform for 1:M directories, exiting if any errors are produced

program_log () {
  echo "${0}: ${1}"
}

error_log () {
  echo "Error: ${1}"
}

# Check for Terraform
if ! command -v terraform &> /dev/null; then
    error_log "Terraform could not be found. This script requires the Terraform CLI."
    echo "See https://learn.hashicorp.com/tutorials/terraform/install-cli for installation instructions."
    exit 1
fi

validate_tf() {
  local tf_dir=$1
  cd "$tf_dir" || exit 1
  program_log "validating at $tf_dir..."
  terraform init -backend=false >> /dev/null || exit 1
  terraform validate >> /dev/null || exit 1
}

working_dir=$(pwd)

for arg in "$@"
do
  cd "$working_dir" || exit 1
  validate_tf "$(realpath "$arg")"
done

program_log "done!"
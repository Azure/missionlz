#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Check Terraform formatting for 1:M directories, exiting if any errors are produced

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

format_tf() {
  local tf_dir=$1
  cd "$tf_dir" || exit 1
  program_log "checking formatting at $tf_dir..."
  if terraform fmt -check -recursive >> /dev/null;
  then
    program_log "successful check with 'terraform fmt -check -recursive ${tf_dir}'"
  else
    linting_results=$(terraform fmt -check -recursive)
    for j in $linting_results
    do
      error_log "'${j}' is not formatted correctly. Format with the command 'terraform fmt ${j}'"
    done
    program_log "run 'terraform fmt -recursive' to format all Terraform components in a directory"
    exit 1;
  fi
}

working_dir=$(pwd)

for arg in "$@"
do
  cd "$working_dir" || exit 1
  format_tf "$(realpath "$arg")"
done

program_log "done!"
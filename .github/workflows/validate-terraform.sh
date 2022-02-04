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

# check for Terraform
if ! command -v terraform &> /dev/null; then
    error_log "Terraform could not be found. This script requires the Terraform CLI."
    echo "See https://learn.hashicorp.com/tutorials/terraform/install-cli for installation instructions."
    exit 1
fi

# validate Terraform with `terraform validate`
validate() {
  local tf_dir=$1
  cd "${tf_dir}" || exit 1
  program_log "validating at ${tf_dir}..."
  terraform init -backend=false >> /dev/null || exit 1
  terraform validate >> /dev/null || exit 1
  program_log "successful validation with \"terraform validate ${tf_dir}\"!"
}

# check Terraform formatting with `terraform fmt`
check_formatting() {
  local tf_dir=$1
  cd "${tf_dir}" || exit 1
  program_log "checking formatting at ${tf_dir}..."
  if terraform fmt -check -recursive >> /dev/null;
  then
    program_log "successful check with \"terraform fmt -check -recursive ${tf_dir}\""
  else
    linting_results=$(terraform fmt -check -recursive)
    for j in $linting_results
    do
      error_log "\"${j}\" is not formatted correctly. Format with the command \"terraform fmt ${j}\""
    done
    program_log "run \"terraform fmt -recursive\" to format all Terraform components in a directory"
    exit 1
  fi
}

# get the starting directory
working_dir=$(pwd)

# for every argument, try to validate and check formatting
for arg in "$@"
do
  real_path=$(realpath "${arg}")
  validate "${real_path}"
  check_formatting "${real_path}"
  cd "${working_dir}" || exit 1
done

program_log "done!"

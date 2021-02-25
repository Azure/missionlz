#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Validates and lints terraform, exiting if any errors are produced

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

# Navigate to the root of the repository
cd .. || exit
rootdir=$(pwd)

# Validate all .tf files
program_log "Validating all terraform"
for i in $(find . -name "*.tf" -printf "%h\n" | sort --unique)
do
  cd "${i}" || exit
  echo "validating ${i}..."
  terraform init -backend=false >> /dev/null || exit 1
  terraform validate >> /dev/null || exit 1
  cd "${rootdir}" || exit
done
program_log "All terraform validated successfully"

# Check formatting for all .tf files
program_log "Linting all terraform"
if terraform fmt -check -recursive >> /dev/null;
then
  program_log "All terraform linted successfully"
else
  linting_results=$(terraform fmt -check -recursive)
  for j in $linting_results
  do
    error_log "please format '${j}' with the command 'terraform fmt'"
  done
  exit 1;
fi
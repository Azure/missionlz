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

full_path=$(realpath "${0}")
repo_path=$(dirname "$(dirname "${full_path}")")
core_path="${repo_path}/core"

if [ -d "$core_path" ];
then
  # Validate all .tf and their dependencies in core_path
  program_log "Validating Terraform..."
  cd "${core_path}" || exit
  for i in $(find . -name "*.tf" -printf "%h\n" | sort --unique)
  do
    cd "${i}" || exit
    echo "validating ${i}..."
    terraform init -backend=false >> /dev/null || exit 1
    terraform validate >> /dev/null || exit 1
    cd "${core_path}" || exit
  done
  program_log "Terraform validated successfully!"

  # Check formatting in all .tf files in repo
  program_log "Linting Terraform..."
  cd "${repo_path}" || exit
  if terraform fmt -check -recursive >> /dev/null;
  then
    program_log "Terraform linted successfully!"
  else
    linting_results=$(terraform fmt -check -recursive)
    for j in $linting_results
    do
      error_log "please format '${j}' with the command 'terraform fmt'"
    done
    program_log "alternatively, you can run 'terraform fmt -recursive' to format all *.tf in a directory"
    exit 1;
  fi
fi

#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Get MLZ Configuration and Terraform Variables from a storage account

set -e

# create some place to hold the configuration and TF vars
rm -rf "vars"
mkdir "vars"

# download everything in the container to that place
az storage blob download-batch \
  --account-name "${STORAGEACCOUNT}" \
  --sas-token "${STORAGETOKEN}" \
  --source "${STORAGECONTAINER}" \
  --pattern "*" \
  --destination "vars" \
  --output "none" \
  --only-show-errors

# remove Windows EOL characters
for file in vars/*; do
  sed -i 's/\r$//' "${file}"
done

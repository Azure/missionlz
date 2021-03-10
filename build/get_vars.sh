#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Get MLZ Configuration and Terraform Variables from a storage account

az storage blob download-batch \
  --account-name "${STORAGEACCOUNT}" \
  --sas-token "${STORAGETOKEN}" \
  --source "${STORAGECONTAINER}" \
  --pattern "*" \
  --destination "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" \
  --output "none" \
  --only-show-errors
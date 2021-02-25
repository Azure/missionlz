#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Check for Terraform
if ! command -v terraform &> /dev/null; then
    echo "terraform could not be found. This script requires the Terraform CLI."
    echo "see https://learn.hashicorp.com/tutorials/terraform/install-cli for installation instructions."
    exit 1
fi
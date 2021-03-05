#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

set -e

# Check for Azure CLI
if ! command -v az &> /dev/null; then
    echo "az could not be found. This script requires the Azure CLI."
    echo "see https://docs.microsoft.com/en-us/cli/azure/install-azure-cli for installation instructions."
    exit 1
fi

# Check for Azure CLI account
if ! az account show &> /dev/null; then
    echo "Please login to Azure CLI before running this script."
    echo "To set the cloud: az cloud set --name <cloud name>"
    echo "To login as a Service Principal: az login --service-principal -u <client id> --password=<client secret> --tenant <tenant id> --allow-no-subscriptions"
    echo "To login interactively: az login --username <your upn>"
    exit 1
fi

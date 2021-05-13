#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

set -e

# Check for zip
if ! command -v zip &> /dev/null; then
    echo "zip could not be found. This script requires zip."
    echo "On debian based distributions you can try this to install it: sudo apt install zip"
    exit 1
fi

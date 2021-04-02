#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

set -e

# Check for docker CLI
if ! command -v docker &> /dev/null; then
    echo "docker could not be found. This script requires the docker CLI."
    echo "see https://docs.docker.com/engine/install/ for installation instructions."
    exit 1
fi

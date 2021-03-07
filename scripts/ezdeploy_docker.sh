#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1090,SC1091
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC1091: Not following. Shellcheck can't follow non-constant source.
#
# This script builds and tags the docker image

# Check for Azure CLI
if ! command -v docker &> /dev/null; then
    echo "Docker could not be found.  Docker is required to build docker images."
    echo "see https://docs.docker.com/engine/install/ubuntu for installation instructions."
    exit 1
fi

echo "INFO: building docker container"
docker build -t lzfront ./../
docker tag lzfront:latest $acr_name.azurecr.io/lzfront:latest

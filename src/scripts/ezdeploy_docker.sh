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

set -e

error_log() {
  echo "${1}" 1>&2;
}

# Check for Docker CLI
if ! command -v docker &> /dev/null; then
    echo "Docker could not be found.  Docker is required to build docker images."
    echo "see https://docs.docker.com/engine/install/ubuntu for installation instructions."
    exit 1
fi

usage() {
  echo "ezdeploy_docker.sh: If using 'load' will load from a specified zip file, if using 'build' will build the docker image from the dockerfile."
  error_log "usage: ezdeploy_docker.sh <load|build> {{default=build}}"
}

if [[ "$#" -lt 1 ]]; then
   usage
   exit 1
fi

echo "INFO: building docker container"
    if [[ "${1}" == "build" ]]; then
        docker build -t lzfront "${BASH_SOURCE%/*}/../"
    elif [[ "${1}" == "load" ]]; then
        #TODO: Change this to a file pointer
        unzip mlz.zip .
        docker load -i mlz.tar
    else
        echo "Unrecognized docker strategy detected. Must be build or load"
    fi


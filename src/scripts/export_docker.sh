#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=SC1083,SC1090,SC1091,2154
# SC1083: This is literal.
# SC1090: Can't follow non-constant source. Use a directive to specify location.
# SC1091: Not following. Shellcheck can't follow non-constant source.
# SC2154: "var is referenced but not assigned". These values come from an external file.
#
# This script locally saves a local docker image for movement between airgapped networks. 

set -e

error_log() {
  echo "${1}" 1>&2;
}

show_help() {
  print_formatted() {
    long_name=$1
    char_name=$2
    desc=$3
    printf "%20s %2s %s \n" "$long_name" "$char_name" "$desc"
  }
  print_formatted "argument" "" "description"
  print_formatted "--output-file" "-f" "Output file name/location, defaults to same directory 'mlz.zip'"
}

usage() {
  echo "export_docker.sh: Builds MLZ UI and Templates into a dockerfile for movement to another network"
  show_help
}

# default file name
zip_file="mlz.zip"

# inspect user input
while [ $# -gt 0 ] ; do
  case $1 in
    -f | --output-file) zip_file="$2" ;;
  esac
  shift
done

# build/load, tag, and push image
this_script_path=$(realpath "${BASH_SOURCE%/*}")
src_path=$(dirname "${this_script_path}")
image_name="lzfront"
image_tag="latest"

echo "INFO: building docker image"
docker build -t "${image_name}" "${src_path}"

echo "INFO: Saving docker image and compressing it before exiting."
docker save "${image_name}:${image_tag}" -o mlz.tar
zip "${zip_file}" mlz.tar
rm mlz.tar
echo "INFO: Compressed deployable archive is saved locally as ${zip_file}."
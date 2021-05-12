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
  print_formatted "--help" "-h" "Print this message"
}

usage() {
  echo "export_docker.sh: Builds MLZ UI and Templates into a dockerfile for movement to another network"
  show_help
}

# set paths
this_script_path=$(realpath "${BASH_SOURCE%/*}")
scripts_path="$(realpath ${this_script_path}/../)"
src_path="$(realpath ${this_script_path}/../../)"

# check for zip
"${this_script_path}/../util/checkforzip.sh"

# default file name
zip_file="mlz.zip"

# inspect user input
while [ $# -gt 0 ] ; do
  case $1 in
    -f | --output-file)
      shift
      zip_file="$1" ;;
    -h | --help)
      show_help
      exit 0 ;;
    *)
      error_log "ERROR: Unexpected argument: ${1}"
      usage && exit 1 ;;
  esac
  shift
done

# build and zip the image
zip_name="${scripts_path}/${zip_file}"
image_name="lzfront"
image_tag="latest"

echo "INFO: building docker image ${image_name}:${image_tag}..."
docker build -t "${image_name}" "${src_path}"

echo "INFO: saving docker image and compressing it to ${zip_name}..."
docker save "${image_name}:${image_tag}" -o mlz.tar
zip "${zip_name}" mlz.tar
rm mlz.tar
echo "INFO: Complete! Compressed deployable archive is saved locally as ${zip_name}"
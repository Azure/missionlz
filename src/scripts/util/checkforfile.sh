#!/bin/bash
#
# Check for an empty or missing file and return an error

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "checkforfile.sh: Check for an empty or missing file and return an error"
  error_log "usage: checkforfile.sh <file path> <error message>"
}

if [[ "$#" -lt 2 ]]; then
   usage
   exit 1
fi

file_path=$1
error_message=$2

if [[ ! -s "${file_path}" ]]; then
   error_log "${error_message}"
   exit 1
fi
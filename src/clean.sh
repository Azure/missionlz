#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=1090,2154
#
# remove resources deployed by deploy.sh by mlz env name

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
  print_formatted "--mlz-env-name" "-z" "[OPTIONAL] Unique name for MLZ environment (defaults to 'mlz' + UNIX timestamp)"
}

usage() {
  echo "clean.sh: remove resources deployed by deploy.sh by mlz env name"
  show_help
}

this_script_path=$(realpath "${BASH_SOURCE%/*}")
configuration_output_path="${this_script_path}/generated-configurations"

# check for dependencies

"${this_script_path}/scripts/util/checkforazcli.sh"
"${this_script_path}/scripts/util/checkforterraform.sh"

# inspect user input
while [ $# -gt 0 ] ; do
  case $1 in
    -z | --mlz-env-name) mlz_env_name="$2" ;;
  esac
  shift
done

# check mandatory parameters
# shellcheck disable=1083
for i in { $mlz_env_name }
do
  if [[ $i == "notset" ]]; then
    error_log "ERROR: Missing required arguments. These arguments are mandatory: -z"
    usage
    exit 1
  fi
done

# source generated config
mlz_config_file="${configuration_output_path}/${mlz_env_name}.mlzconfig"
. "${mlz_config_file}"

# generate names for reference
. "${this_script_path}/scripts/config/generate_names.sh" "${mlz_config_file}"

# source generated terraform vars
tfvars_filename="${mlz_env_name}.tfvars"
tfvars_path="${configuration_output_path}/${tfvars_filename}"

# login
echo "INFO: setting current subscription to ${mlz_config_subid}..."
az account set \
  --subscription "${mlz_config_subid}" \
  --only-show-errors \
  --output none

# destroy terraform
echo "INFO: destroying Terraform using ${mlz_config_file} and ${tfvars_path}..."
"${this_script_path}/build/destroy_tf.sh" \
  "${mlz_config_file}" \
  "${tfvars_path}" \
  "${tfvars_path}" \
  "${tfvars_path}" \
  "${tfvars_path}" \
  "${tfvars_path}" \
  "y"

# clean up MLZ config resources
echo "INFO: cleaning up MLZ resources with tag 'DeploymentName=${mlz_env_name}'..."

# Create array of unique subscription IDs. The 'sed' command below search thru the source
# variables file looking for all lines that do not have a '#' in the line. If a line with
# a '#' is found, the '#' and ever character after it in the line is ignored. The output
# of what remains from the sed command is then piped to grep to find the words that match
# the pattern. These words are what make up the 'mlz_subs' array.
mlz_sub_pattern="mlz_.*._subid"
mlz_subs=$(< "${mlz_config_file}" sed 's:#.*$::g' | grep -w "${mlz_sub_pattern}")
subs=()

for mlz_sub in $mlz_subs
do
    mlz_sub_id=$(echo "${mlz_sub#*=}" | tr -d '"')
    if [[ ! "${subs[*]}" =~ ${mlz_sub_id} ]];then
        subs+=("${mlz_sub_id}")
    fi
done

# delete resource groups where deploymentname is mlz_env_name in each subscription
for sub in "${subs[@]}";
do
  rgs_to_delete=$(az group list --subscription ${sub} --tag DeploymentName="${mlz_env_name}" --query [].name -o tsv)
  for rg in $rgs_to_delete;
  do
    echo "INFO: deleting ${rg}..."

    az group delete \
      --name "${rg}" \
      --yes \
      --only-show-errors \
      --output none
  done
done

echo "INFO: deleting service principal ${mlz_sp_name}..."
az ad sp delete --id "http://${mlz_sp_name}"

echo "INFO: Complete! Resources for ${mlz_env_name} deleted!"

#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=1090,2154
#
# remove mlz configuration resources from an mlz configuration file

set -e

error_log() {
  echo "${1}" 1>&2;
}

usage() {
  echo "config_clean.sh: remove mlz configuration resources from an mlz configuration file"
  error_log "usage: config_clean.sh <mlz config>"
}

if [[ "$#" -lt 1 ]]; then
   usage
   exit 1
fi

mlz_config_file=$(realpath "${1}")
this_script_path=$(realpath "${BASH_SOURCE%/*}")

# check for dependencies
"${this_script_path}/../util/checkforazcli.sh"
"${this_script_path}/../util/checkforterraform.sh"
"${this_script_path}/../util/checkforfile.sh" \
   "${mlz_config_file}" \
   "The configuration file ${mlz_config_file} is empty or does not exist."

# generate names from config
. "${mlz_config_file}"
. "${this_script_path}/generate_names.sh" "${mlz_config_file}"

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
  rgs_to_delete=$(az group list --subscription "${sub}" --tag "DeploymentName=${mlz_config_tag}" --query [].name -o tsv)
  for rg in $rgs_to_delete;
  do
    echo "INFO: deleting ${rg}..."

    az group delete \
      --subscription "${sub}" \
      --name "${rg}" \
      --yes \
      --only-show-errors \
      --output none
  done
done

echo "INFO: querying for any created service principal with name ${mlz_sp_name}..."
sp_id=$(az ad sp list --display-name "http://${mlz_sp_name}" --query [0].appId --output tsv)

if [[ $sp_id ]]; then
  echo "INFO: deleting service principal ${mlz_sp_name}..."
  az ad sp delete --id "${sp_id}"
fi

echo "INFO: purging key vault ${mlz_kv_name}..."
az keyvault purge \
    --name "${mlz_kv_name}" \
    --subscription "${mlz_config_subid}"

echo "INFO: Complete! MLZ Configuration resources for ${mlz_env_name} deleted!"
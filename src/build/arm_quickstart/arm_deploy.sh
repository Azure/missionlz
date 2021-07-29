#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# shellcheck disable=1091,2155
#
# create all the configuration and deploy Terraform resources with minimal input

set -e

error_log() {
  echo "${1}" 1>&2;
}
# Prepare the CLI Container with requirements

# Download and Install Terraform
wget -O terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
unzip ./terraform.zip -d /usr/local/bin/
rm terraform.zip

# Check out the MLZ Repo
git clone --quiet https://github.com/Azure/missionlz.git
cd ./missionlz/src/scripts

# Assemble argument list
az login --service-principal \
--user "${ARM_CLIENT_ID}" \
--password "${ARM_CLIENT_SECRET}" \
--tenant "${env_tenant_id}" \
--allow-no-subscriptions \
--output json

./deploy.sh -s "${subscription_id}" -l "${mlz_location}" -e "${tf_environment}" -z "${mlz_env_name}" -w --no-bastion --no-sentinel --no-subscription-id
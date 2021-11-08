#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Steps through current logged in az cli subscriptions and deletes resource groups based on first arg,
#   as filter as a job by not waiting for them to complete.
#
# Then steps through each diagnostic setting at subscription level with similar filter, 
#   resets az cli account to a specific subscription to be able to continue to use command line.
#   Usage: ./delete.sh "<filter to use in RG name search>" "<subscription ID to end in>"

for subscription in $(az account list -o tsv); do
    az account set --subscription "${subscription}"
        for rgname in $(az group list --query "[? contains(name,'$1')][].{name:name}" -o tsv); do
        echo Deleting "${rgname}"
        az group delete -n "${rgname}" --yes --no-wait
        done
        for setting in $(az monitor diagnostic-settings subscription list --query "value[? contains(@.name, '$1')].name" -o tsv); do
            echo Deleting "${setting}"
            az monitor diagnostic-settings delete --name "${setting}" --resource /subscriptions/"${subscription}"
        done    
done

az account set --subscription "$2"

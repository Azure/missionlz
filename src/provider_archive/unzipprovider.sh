#!/bin/bash
#
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Unzips the azurerm 2.45.1 terraform provider into the provider_cache directory
# then sets it to executable

parentdir="$(dirname "$(realpath "${BASH_SOURCE%/*}")")"

src_azurerm="${BASH_SOURCE%/*}/terraform-provider-azurerm_2.45.1_linux_amd64.zip"
azurerm_filename=$(unzip -Z -1 "${src_azurerm}")
dest_azurerm="${parentdir}/provider_cache/registry.terraform.io/hashicorp/azurerm/2.45.1/linux_amd64/"
unzip -o -d "$dest_azurerm" "$src_azurerm"
chmod u+x "${dest_azurerm}/${azurerm_filename}"

src_random="${BASH_SOURCE%/*}/terraform-provider-random_3.1.0_linux_amd64.zip"
random_filename=$(unzip -Z -1 "${src_random}")
dest_random="${parentdir}/provider_cache/registry.terraform.io/hashicorp/random/3.1.0/linux_amd64/"
unzip -o -d "$dest_random" "$src_random"
chmod u+x "${dest_random}/${random_filename}"

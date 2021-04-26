# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
FROM ubuntu:20.04

# Instructs apt-get to run without a terminal
ENV DEBIAN_FRONTEND=noninteractive

# Update distro (software-properties-common installs the add-apt-repository command)
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils software-properties-common 2>&1 \
    && apt-get dist-upgrade -y \
    && add-apt-repository ppa:git-core/ppa \
    && apt-get install -y \
        unzip \
        wget \
        python3 \
        sed \ 
        python3-pip


# Install Terraform and Python
RUN wget -O terraform.zip https://releases.hashicorp.com/terraform/0.14.3/terraform_0.14.3_linux_amd64.zip\
    && unzip ./terraform.zip -d /usr/local/bin/ \
    && rm terraform.zip 

# Download Terraform providers (plugins)
# Setting the TF_PLUGIN_CACHE_DIR environment variable instructs Terraform to search that folder for plugins first
ENV TF_PLUGIN_CACHE_DIR=/usr/lib/tf-plugins
ARG AZURERM_LOCAL_PATH="${TF_PLUGIN_CACHE_DIR}/registry.terraform.io/hashicorp/azurerm/2.55.0/linux_amd64"
ARG RANDOM_LOCAL_PATH="${TF_PLUGIN_CACHE_DIR}/registry.terraform.io/hashicorp/random/3.1.0/linux_amd64"
ARG AZURERM_PROVIDER=https://releases.hashicorp.com/terraform-provider-azurerm/2.55.0/terraform-provider-azurerm_2.55.0_linux_amd64.zip
ARG RANDOM_PROVIDER=https://releases.hashicorp.com/terraform-provider-random/3.1.0/terraform-provider-random_3.1.0_linux_amd64.zip
RUN wget -O azurerm.zip ${AZURERM_PROVIDER} \
    && wget -O random.zip ${RANDOM_PROVIDER} \
    && mkdir -p ${AZURERM_LOCAL_PATH} \
    && mkdir -p ${RANDOM_LOCAL_PATH} \
    && unzip azurerm.zip -d ${AZURERM_LOCAL_PATH} \
    && unzip random.zip -d ${RANDOM_LOCAL_PATH} \
    && rm azurerm.zip \
    && rm random.zip

# Install the Microsoft package key
RUN wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb

# Install the Microsoft signing key
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | \
    tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

# Install the AZ CLI repository
RUN AZ_REPO=$(lsb_release -cs) \
    && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
    tee /etc/apt/sources.list.d/azure-cli.list

# Install AZ CLI
RUN apt-get update && apt-get install -y azure-cli

ADD ./front* /deployment/front/
ADD ./scripts* /deployment/scripts/
ADD ./core* /deployment/core/
ADD ./modules* /deployment/modules/
ADD ./build* /deployment/build/

RUN pip3 install -r /deployment/front/requirements.txt


# Reset to the default value
ENV DEBIAN_FRONTEND=dialog

WORKDIR /deployment/front

ENTRYPOINT python3 main.py


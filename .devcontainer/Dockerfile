# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
FROM ubuntu:20.04

# Instructs apt-get to run without a terminal
ENV DEBIAN_FRONTEND=noninteractive

# Terraform, providers and tflint versions
ARG TERRAFORM_VERSION=1.2.9
ARG AZURERM_VERSION=3.23.0
ARG RANDOM_VERSION=3.4.3
ARG TIME_VERSION=0.8.0
ARG TFLINT_VERSION=0.40.0
ARG TFLINT_AZURERM=0.18.0

# Azure CLI version
ARG AZURE_CLI_VERSION=2.40.0-1~focal

# Bicep version
ARG BICEP_VERSION=v0.10.61

# Update distro (software-properties-common installs the add-apt-repository command)
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils software-properties-common 2>&1 \
    && apt-get dist-upgrade -y

# Install prerequisites
RUN add-apt-repository ppa:git-core/ppa \
    && apt-get install -y \
    apt-transport-https \
    wget \
    unzip \
    git \
    ca-certificates \
    curl \
    lsb-release \
    gnupg \
    sudo \
    shellcheck

# Install Terraform and tflint
RUN wget -O terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && wget -O tflint.zip https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip \
    && unzip ./terraform.zip -d /usr/local/bin/ \
    && unzip ./tflint.zip -d /usr/local/bin/ \
    && rm terraform.zip \
    && rm tflint.zip

# Download Terraform providers (plugins)
# Setting the TF_PLUGIN_CACHE_DIR environment variable instructs Terraform to search that folder for plugins first
ENV TF_PLUGIN_CACHE_DIR=/usr/lib/tf-plugins
ENV TFLINT_PLUGIN_DIR=/usr/lib/tflint-plugins
ARG AZURERM_LOCAL_PATH="${TF_PLUGIN_CACHE_DIR}/registry.terraform.io/hashicorp/azurerm/${AZURERM_VERSION}/linux_amd64"
ARG RANDOM_LOCAL_PATH="${TF_PLUGIN_CACHE_DIR}/registry.terraform.io/hashicorp/random/${RANDOM_VERSION}/linux_amd64"
ARG TIME_LOCAL_PATH="${TF_PLUGIN_CACHE_DIR}/registry.terraform.io/hashicorp/time/${TIME_VERSION}/linux_amd64"
ARG AZURERM_PROVIDER=https://releases.hashicorp.com/terraform-provider-azurerm/${AZURERM_VERSION}/terraform-provider-azurerm_${AZURERM_VERSION}_linux_amd64.zip
ARG RANDOM_PROVIDER=https://releases.hashicorp.com/terraform-provider-random/${RANDOM_VERSION}/terraform-provider-random_${RANDOM_VERSION}_linux_amd64.zip
ARG TIME_PROVIDER=https://releases.hashicorp.com/terraform-provider-time/${TIME_VERSION}/terraform-provider-time_${TIME_VERSION}_linux_amd64.zip
ARG AZURERM_TFLINT_PLUGIN=https://github.com/terraform-linters/tflint-ruleset-azurerm/releases/download/v${TFLINT_AZURERM}/tflint-ruleset-azurerm_linux_amd64.zip
RUN wget -O azurerm.zip ${AZURERM_PROVIDER} \
    && wget -O random.zip ${RANDOM_PROVIDER} \
    && wget -O time.zip ${TIME_PROVIDER} \
    && wget -O tflintazurerm.zip ${AZURERM_TFLINT_PLUGIN} \
    && mkdir -p ${AZURERM_LOCAL_PATH} \
    && mkdir -p ${RANDOM_LOCAL_PATH} \
    && mkdir -p ${TIME_LOCAL_PATH} \
    && unzip azurerm.zip -d ${AZURERM_LOCAL_PATH} \
    && unzip random.zip -d ${RANDOM_LOCAL_PATH} \
    && unzip time.zip -d ${TIME_LOCAL_PATH} \
    && unzip tflintazurerm.zip -d ${TFLINT_PLUGIN_DIR} \
    && rm azurerm.zip \
    && rm random.zip \
    && rm time.zip \
    && rm tflintazurerm.zip

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
RUN apt-get update && apt-get install -y azure-cli=${AZURE_CLI_VERSION}

# Install Bicep
RUN curl -Lo /usr/local/bin/bicep https://github.com/Azure/bicep/releases/download/${BICEP_VERSION}/bicep-linux-x64 \
    && chmod +x /usr/local/bin/bicep

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Add the vscode user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USERNAME -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Reset to the default value
ENV DEBIAN_FRONTEND=dialog

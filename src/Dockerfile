FROM ubuntu:20.04

# Instructs apt-get to run without a terminal
ENV DEBIAN_FRONTEND=noninteractive

ADD ./front* /app/

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
        python3-pip

# Install Terraform
RUN wget -O terraform.zip https://releases.hashicorp.com/terraform/0.14.3/terraform_0.14.3_linux_amd64.zip\
    && unzip ./terraform.zip -d /usr/local/bin/ \
    && rm terraform.zip

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

# Install dotnet core
RUN apt-get install -y \
    dotnet-sdk-3.1 \
    azure-functions-core-tools-3

# Reset to the default value
ENV DEBIAN_FRONTEND=dialog

WORKDIR /app

RUN pip3 install -r requirements.txt

ENTRYPOINT python3 main.py


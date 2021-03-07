FROM ubuntu:20.04

# Instructs apt-get to run without a terminal
ENV DEBIAN_FRONTEND=noninteractive

ADD ./front* /app/

# Update distro (software-properties-common installs the add-apt-repository command)
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils software-properties-common 2>&1 \
    && apt-get dist-upgrade -y
    && add-apt-repository ppa:git-core/ppa \
    && apt-get install -y \
        python3 \
        python3-pip

# Install Terraform and Python
RUN wget -O terraform.zip https://releases.hashicorp.com/terraform/0.14.3/terraform_0.14.3_linux_amd64.zip\
    && unzip ./terraform.zip -d /usr/local/bin/ \
    && rm terraform.zip
    && pip3 install -r requirements.txt

# Reset to the default value
ENV DEBIAN_FRONTEND=dialog

WORKDIR /app

ENTRYPOINT python3 main.py


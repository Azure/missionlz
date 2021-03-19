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
        python3-pip

ADD ./front* /deployment/front/

# Install Terraform and Python
RUN wget -O terraform.zip https://releases.hashicorp.com/terraform/0.14.3/terraform_0.14.3_linux_amd64.zip\
    && unzip ./terraform.zip -d /usr/local/bin/ \
    && rm terraform.zip \
    && pip3 install -r /deployment/front/requirements.txt

ADD ./scripts* /deployment/scripts/
ADD ./core* /deployment/core/
ADD ./modules* /deployment/modules/

# Reset to the default value
ENV DEBIAN_FRONTEND=dialog

WORKDIR /deployment/front

ENTRYPOINT python3 main.py


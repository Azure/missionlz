# Mission LZ Front End

The mission LZ front-end is designed to be a single stop for easily entering all of the configuration items that terraform needs to deploy mission lz to a target set of subscriptions.  

## Getting Started

In order to run this software, you'll need to install some requirements, regardless of the path you choose to take for execution.  Follow the General Requirements,  and then follow instructions for either remote or local installation

For any of the following options you will need docker on your machine. If you are pre-packaging and deploying on a target network, you will need docker locally installed on both your local internet connected machine, and your target machine.  The below instructions might need to be found in your target environment to replicate. 

Install Docker:

1. [Install Docker Linux](https://docs.docker.com/engine/install/ubuntu)
2. [Install Docker WSl2](https://docs.microsoft.com/en-us/windows/wsl/tutorials/wsl-containers)

Notes:
If you will be transferring this package to an air-gapped cloud, please run the pre-packaging requirements to build a package that's ready to be transferred.  This will prepare a docker image with all requirements to run ezdeploy.  This is necessary if you don't have access to an updated docker repo/pip repo in your target network.  If you do have these, you can proceed with the installation as if installing to an internet connected Azure Cloud.

[General Requirements](#General-Requirements)  
[Remote Installation/Execution](#Remote-Installation-Instructions)  
[Local Installation/Execution](#Local-Installation-Instructions)

## General Requirements

To get started, you'll need to be running from a bash/zsh environment.  If you are on a Windows machine you can use WSL2.

Install WSL2:

1. [Install WSL2](https://docs.microsoft.com/en-us/windows/wsl/install-win10)

Install Azure CLI:

1. [Install Azure CLI](#Install-Azure-CLI)

## Remote-Installation-Instructions

In order to run all of ezdeploy remotely, you'll need to have docker installed locally, as well as the Azure Bash CLI

From the "src" directory

    ```bash
    chmod u+x ./scripts/setup_ezdeploy.sh
    ./scripts/setup_ezdeploy.sh build <subscription_id> <tenant_id> <location> -t <tf_env_name> -m <mlz_env_name> -p <port>
    ```

The final results will include a URI that you can use to access the front end running in a remote azure container instance

## Local-Installation-Instructions

Install Python 3:

1. [Install Python](#Installing-Python)

1. [Install Docker-Compose](#Install-Docker-Compose)

1. [Install Azure CLI Linux](#Installing-Azure)

### Installing Azure

Installation instructions below are primarily for Ubuntu 20.04.  You may need to find different instructions for other flavors of Linux.

    ```bash
    # Install the AZ CLI repository
    AZ_REPO=$(lsb_release -cs) \
    && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
    tee /etc/apt/sources.list.d/azure-cli.list

    # Install AZ CLI
    apt-get update && apt-get install -y azure-cli
    ```

### Installing Python

Basic Installation Instructions for Ubuntu 20.04.   You may need to find different instructions for other flavors of Linux.

    ```bash
    apt-get update \
        && apt-get install -y \
        python3 \
        python3-pip \
        && ln -s /usr/bin/python3 /usr/bin/python \
        && ln -s /usr/bin/pip3 /usr/bin/pip
    ```

### Local-Execution

Before running locally, you must follow the instructions in the primary readme file for this repo.  You must have terraform pre-requisites installed in order to execute from a local system. Local execution will also require your credentials to have access to the service principal credentials for this system to assume; meaning that you should perform:

    ```bash
    az login
    ```

prior to following the following instructions

1. Install and Source a Python Virtual Environment

        ```bash
        python3 -m venv /path/to/new/virtual/environment
        source /path/to/new/virtual/environment/bin/activate
        ```

2. Install requirements via pip

        ```bash
        pip install -r src/front/requirements.txt
        ```

3. Run the installation scripts to deploy app requirements

    You will need the following variables for the script:

    subscription_id: is the subscription that will house all deployment artifacts: kv, storage, fe instance

    tenant_id:  the tenant_id where all of your subscriptions are located

    tf_env_name: Please refer to [https://www.terraform.io/docs/language/settings/backends/azurerm.html#environment] for more information.   (Defaults to Public)

    mlz_env_name: Can be anything unique to your deployment/environment it is used to ensure unique entries for resources.  (Defaults to mlzdeployment)

    port:  Default is 80, if you are running in WSL or otherwise can't bind to 80, use this flag to enter a port

        ```bash
        chmod u+x ./script/setup_ezdeploy.sh
        ./script/setup_ezdeploy.sh local <subscription_id> <tenant_id> <location> -t <tf_env_name> -m <mlz_env_name> -p port
        ```

4. Invoke environment variables needed for login (These are returned after setup_ezdeploy.sh is run)

        ```powershell
        $env:CLIENT_ID="<CLIENT_ID>"
        $env:CLIENT_SECRET="<CLIENT_SECRET"
        $env:TENANT_ID="<TENANT_ID>"
        $env:LOCATION='<CLOUD_LOCATION>'
        $env:SUBSCRIPTION_ID='<SUBSCRIPTION_ID>'
        $env:TF_ENV='<TERRAFORM_ENVIRONMENT>'
        $env:MLZ_ENV='<ENVIRONMENT_NAME>'
        ```

        ```bash
        export CLIENT_ID="<CLIENT_ID>"
        export CLIENT_SECRET="<CLIENT_SECRET"
        export TENANT_ID="<TENANT_ID>"
        export LOCATION='<CLOUD_LOCATION>'
        export SUBSCRIPTION_ID='<SUBSCRIPTION_ID>'
        export TF_ENV='<TERRAFORM_ENVIRONMENT>'
        export MLZ_ENV='<ENVIRONMENT_NAME>'
        ```

5. Execute web server

        ```bash
        python main.py <port_if_not_80>
        ```

    You can then access the application by pointing your browser at "localhost"

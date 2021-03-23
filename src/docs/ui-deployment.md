# Mission LZ User Interface

The mission LZ front-end is designed to be a single stop for easily entering all of the configuration items that Terraform needs to deploy Mission LZ to a target set of subscriptions.  

## General Requirements

In order to run this software, you'll need to install some requirements, regardless of the path you choose to take for execution. Follow the General Requirements, and then follow instructions for either remote or local installation

For any of the following options you will need docker on your machine. If you are pre-packaging and deploying on a target network, you will need docker locally installed on both your local internet connected machine, and your target machine.  The below instructions might need to be found in your target environment to replicate.

1. Install [Install WSL2](https://docs.microsoft.com/en-us/windows/wsl/install-win10) and [Docker on Windows for WSL2](https://docs.microsoft.com/en-us/windows/wsl/tutorials/wsl-containers), or [Install Docker Linux](https://docs.docker.com/engine/install/ubuntu) (Docker-Compose is also required, and is intalled by default with Docker Desktop.)
1. [Install the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli). Be sure to install the Azure CLI in your Linux or WSL environment.

> If you will be transferring this package to an air-gapped cloud, please run the pre-packaging requirements to build a package that's ready to be transferred. This will prepare a docker image with all requirements to run ezdeploy. This is necessary if you don't have access to an updated docker repo/pip repo in your target network.  If you do have these, you can proceed with the installation as if installing to an internet connected Azure Cloud.  

## Step-By-Step

[Step-by-Step Remote Installation/Execution](#Step-by-Step-Azure-Installation) (recommended)  
[Step-by-Step Local Installation/Execution](#Step-by-Step-Local-Installation) (more difficult)

To get started, you'll need to be running from a bash/zsh environment. If you are on a Windows machine you can use WSL2.

### Step-by-Step Azure Installation

This process will build the user interface container image on your workstation using Docker, upload the container image to your Azure subscription, and install an instance of the container in Azure Container Instances (ACI). You'll need to have Docker installed locally, as well as the Azure Bash CLI.

From the "src" directory

```BASH
chmod u+x ./scripts/setup_ezdeploy.sh
./script/setup_ezdeploy.sh -d build -s <subscription_id> -t <tenant_id> -l <location> -e <tf_env_name> -m <mlz_env_name> -p port -0 <saca_subscription_id> -1 <tier0_subscription_id> -2 <tier1_subscription_id> -3 <tier2_subscription_id>"
```

The final results will include a URI that you can use to access the front end running in a remote azure container instance.

### Step-by-Step Local Installation

Running the user interface on your local workstation is not our recommended approach because it requires more setup, but it works.

1. [Install Python](#Install-Python)
1. [Run the User Interface Locally](#Run-the-User-Interface-Locally)

### Install Python

Basic Installation Instructions for Ubuntu 20.04.   You may need to find different instructions for other flavors of Linux.

```BASH
apt-get update \
    && apt-get install -y \
    python3 \
    python3-pip \
    && ln -s /usr/bin/python3 /usr/bin/python \
    && ln -s /usr/bin/pip3 /usr/bin/pip
```

### Run the User Interface Locally

Before running locally, you must follow the instructions in the primary readme file for this repo.  You must have terraform pre-requisites installed in order to execute from a local system. Local execution will also require your credentials to have access to the service principal credentials for this system to assume; meaning that you should perform:

```BASH
az login
```

prior to following the following instructions

1. Install and Source a Python Virtual Environment

```bash
    python3 -m venv /path/to/new/virtual/environment
    source /path/to/new/virtual/environment/bin/activate
```

2. Install requirements via pip

```BASH
    pip install -r src/front/requirements.txt
```

3. Run the installation scripts to deploy app requirements

    You will need the following variables for the script:

    subscription_id: is the subscription that will house all deployment artifacts: kv, storage, fe instance

    tenant_id:  the tenant_id where all of your subscriptions are located

    tf_env_name: Please refer to [https://www.terraform.io/docs/language/settings/backends/azurerm.html#environment] for more information.   (Defaults to Public)

    mlz_env_name: Can be anything unique to your deployment/environment it is used to ensure unique entries for resources.  (Defaults to mlzdeployment)

    port:  Default is 80, if you are running in WSL or otherwise can't bind to 80, use this flag to enter a port

    Multiple Subscriptions:
    If you are running with multiple subscriptions, you'll need to use these flags with the setup command.

    -0: SACA Hub Subscription ID
    -1: Tier 0 Subscription ID
    -2: Tier 1 Subscription ID
    -3: Tier 2 Subscription ID

```bash
    chmod u+x ./script/setup_ezdeploy.sh
    ./script/setup_ezdeploy.sh -d local -s <subscription_id> -t <tenant_id> -l <location> -e <tf_env_name> -m <mlz_env_name> -p port p -0 <saca_subscription_id> -1 <tier0_subscription_id> -2 <tier1_subscription_id> -3 <tier2_subscription_id>"
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

You can then access the application by pointing your browser at "localhost".

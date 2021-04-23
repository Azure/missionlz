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

Log in using the Azure CLI

```BASH
 az login
```

Then deploy a container instance of the front end with:

```BASH
cd src/scripts
./setup_ezdeploy.sh -s <subscription id>
```

`setup_ezdeploy.sh` has more configurable options, but these are the minimum required to deploy a running UI that will help you make a full MLZ deployment.

Here's the full list of parameters for reference:

```plaintext
setup_ezdeploy.sh: Setup the front end for MLZ
            argument    description
   --docker-strategy -d [local|build|load|export] 'local' for localhost, 'build' to build from this repo, or 'load' to unzip an image, 'export' to build and create mlz.zip with the docker image
   --subscription-id -s Subscription ID for MissionLZ resources
          --location -l The location that you're deploying to (defaults to 'eastus')
    --tf-environment -e Terraform azurerm environment (defaults to 'public') see: https://www.terraform.io/docs/language/settings/backends/azurerm.html#environment
      --mlz-env-name -z Unique name for MLZ environment (defaults to 'mlz' + UNIX timestamp)
              --port -p port to expose the front end web UI on (defaults to '80')
        --hub-sub-id -h subscription ID for the hub network and resources (defaults to the value provided for -s --subscription-id)
      --tier0-sub-id -0 subscription ID for tier 0 network and resources (defaults to the value provided for -s --subscription-id)
      --tier1-sub-id -1 subscription ID for tier 1 network and resources (defaults to the value provided for -s --subscription-id)
      --tier2-sub-id -2 subscription ID for tier 2 network and resources (defaults to the value provided for -s --subscription-id)
```

### Step-by-Step Azure Air Gapped Installation

This process closely mirrors the standard Azure documentation with a few subtle amendments.  

On your internet connected staging machine (With Docker Installed):

Build the docker image needed for deployment:

```BASH
cd src/scripts
./export_docker.sh
```

This will take some time by building the docker image, and then saving it to the scripts working directory and compressing it to "mlz.zip"

Move this file along with the repo to the destination for airgapped deployment Then execute the following

```BASH
cd src/scripts
./setup_ezdeploy.sh -d load -s <subscription id> -e "<AZURE_ENVIRONMENT>" -l "<AZURE_LOCATION>"
```

If desired both commands allow for the input of file names for exporting and for the load if the defaults are not sufficient. 

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

```bash
az login
```

prior to following the following instructions

1. Install and Source a Python Virtual Environment

    ```bash
    python3 -m venv /path/to/new/virtual/environment
    source /path/to/new/virtual/environment/bin/activate
    ```

1. Install requirements via pip

    ```bash
    pip3 install -r src/front/requirements.txt
    ```

1. Run the installation scripts to deploy app requirements

    You will need the following variables for the script:

    `subscription_id`: is the subscription that will house all deployment artifacts: kv, storage, fe instance

    `port`:  Default is 80, if you are running in WSL or otherwise can't bind to 80, use this flag to enter a port (e.g. 8081)

    ```bash
    cd src/scripts
    ./setup_ezdeploy.sh -d local -s <subscription_id> -p <port>
    ```

1. Invoke environment variables needed for login (These are returned after setup_ezdeploy.sh is run)

    ```powershell
    $env:CLIENT_ID='$client_id'
    $env:CLIENT_SECRET='$client_password'
    $env:TENANT_ID='$mlz_tenantid'
    $env:MLZ_LOCATION='$mlz_config_location'
    $env:SUBSCRIPTION_ID='$mlz_config_subid'
    $env:HUB_SUBSCRIPTION_ID='HUB_SUBSCRIPTION_ID=$mlz_saca_subid'
    $env:TIER0_SUBSCRIPTION_ID='TIER0_SUBSCRIPTION_ID=$mlz_tier0_subid'
    $env:TIER1_SUBSCRIPTION_ID='TIER1_SUBSCRIPTION_ID=$mlz_tier1_subid'
    $env:TIER2_SUBSCRIPTION_ID='TIER2_SUBSCRIPTION_ID=$mlz_tier2_subid'
    $env:TF_ENV='$tf_environment'
    $env:MLZ_ENV='$mlz_env_name'
    $env:MLZCLIENTID='$(az keyvault secret show --name "${mlz_sp_kv_name}" --vault-name "${mlz_kv_name}" --query value --output tsv)'
    $env:MLZCLIENTSECRET='$(az keyvault secret show --name "${mlz_sp_kv_password}" --vault-name "${mlz_kv_name}" --query value --output tsv)'
    ```

    ```bash
    export CLIENT_ID=$auth_client_id
    export CLIENT_SECRET=$auth_client_secret
    export TENANT_ID=$mlz_tenantid
    export MLZ_LOCATION=$mlz_config_location
    export SUBSCRIPTION_ID=$mlz_config_subid
    export HUB_SUBSCRIPTION_ID=$mlz_saca_subid
    export TIER0_SUBSCRIPTION_ID=$mlz_tier0_subid
    export TIER1_SUBSCRIPTION_ID=$mlz_tier1_subid
    export TIER2_SUBSCRIPTION_ID=$mlz_tier2_subid
    export TF_ENV=$tf_environment
    export MLZ_ENV=$mlz_env_name
    export MLZCLIENTID=$mlz_client_id
    export MLZCLIENTSECRET=$mlz_client_secret
    ```

1. Execute web server

    ```bash
    cd src/front
    python3 main.py <port_if_not_80>
    ```

You can then access the application by pointing your browser at "localhost".

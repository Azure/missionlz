# Mission LZ Front End

The Mission LZ Front End 
## Getting Started
In order to run this software, you'll need to install some requirements, regardless of the path you choose to take for execution.  Follow the General Requirements,  and then follow instructions for either remote or local installation

For any of the following options you will need docker on your machine. If you are pre-packaging and deploying on a target network, you will need docker locally installed on both your local internet connected machine, and your target machine.  The below instructions might need to be found in your target environment to replicate. 

Install Docker:
1. [Install Docker Linux](https://docs.docker.com/engine/install/ubuntu)
2. [Install Docker WSl2](https://docs.microsoft.com/en-us/windows/wsl/tutorials/wsl-containers)

Notes:
If you will be transferring this package to a sovereign cloud, please run the pre-packaging requirements to build a package that's ready to be transferred.  This will prepare a docker image with all requirements to run ezdeploy.  This is necessary if you don't have access to an updated docker repo/pip repo in your target network.  If you do have these, you can proceed with the installation as if installing to an internet connected Azure Cloud.

[General Requirements](#General-Requirements)
[Pre-Package for AirGap](#Airgap-Prep)
[Remote AirGap Deployment](#Airgap-Remote)
[Local AirGap Deployment](#Airgap-Local)
[Remote Installation/Execution](#Remote-Installation-Instructions)
[Local Installation/Execution](#Local Installation Instructions)

##General Requirements
To get started, you'll need to be running from a bash/zsh environment.  If you are on a Windows machine you can use WSL2.

Install WSL2:
1. [Install WSL2](https://docs.microsoft.com/en-us/windows/wsl/install-win10)

Install Azure CLI:
1. [Install Azure CLI](#Install-Azure-CLI)


##Airgap-Prep


##Remote Installation Instructions (Recommended!)


###Running the Front End

1. [Execute](#Run-Remotely)

##Local Installation/Execution Instructions (WIP, View/Login Only)

Install Python 3:

1. [Install Python](#Installing-Python)



###Install Docker-Compose (Must do after installing python):

1. [Install Docker-Compose](#Install-Docker-Compose)

###Install Azure CLI:

1. [Install Azure CLI Linux](#Installing-Azure)


###Running the Front End

1. [Execute](#Run-Locally) (WIP, view/login only)

```bash
python
```


####Install Azure CLI
Installation instructions below are primarily for Ubuntu 20.04.  You may need to find different instructions for other flavors of Linux.

```bash
# Install the AZ CLI repository
AZ_REPO=$(lsb_release -cs) \
&& echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
tee /etc/apt/sources.list.d/azure-cli.list

# Install AZ CLI
apt-get update && apt-get install -y azure-cli
```


####Installing Python
Basic Installation Instructions for Ubuntu 20.04.   You may need to find different instructions for other flavors of Linux.

```bash
apt-get update \
    && apt-get install -y \
    python3 \
    python3-pip \
    && ln -s /usr/bin/python3 /usr/bin/python \
    && ln -s /usr/bin/pip3 /usr/bin/pip
```

#### Run-Remotely
In order to run all of ezdeploy remotely, you'll need to have docker installed locally, as well as the Azure Bash CLI

```bash
./script/setup_ezdeploy.sh build <subscription_id> <tenant_id> <location> <tf_env_name> <mlz_env_name>
```

The final results will include a URI that you can use to access the front end running in a remote azure container instance

#### Run Locally - No Docker

Before running locally, you must follow the instructions in the primary readme file for this repo.  You must have terraform pre-requisites installed in order to execute from a local system. Local execution will also require your credentials to have access to the service principal credentials for this system to assume. 

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

tf_env_name: Please refer to https://www.terraform.io/docs/language/settings/backends/azurerm.html#environment for more information.   (Defaults to Public)

mlz_env_name: Can be anything unique to your deployment/environment it is used to ensure unique entries for resources.  (Defaults to mlzdeployment)

```bash
./script/setup_ezdeploy.sh local <subscription_id> <tenant_id> <location> <tf_env_name> <mlz_env_name>
```

4. Invoke environment variables needed for login

```powershell
$env:CLIENT_ID="<CLIENT_ID>"
$env:CLIENT_SECRET="<CLIENT_SECRET"
$env:TENANT_ID="<TENANT_ID>"
```

```bash
export CLIENT_ID="<CLIENT_ID>"
export CLIENT_SECRET="<CLIENT_SECRET"
export TENANT_ID="<TENANT_ID>"
```

5. Execute web server
```bash
python main.py
```

You can then access the application by pointing your browser at "localhost"

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
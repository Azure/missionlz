# Getting Started

## Concepts

### Command Line Deployments

You can deploy Mission LZ from your workstation using the command line. Some other configurations are possible, but these are the two simplest paths.

The command-line deployments involve (1) defining configuration settings (we have examples and defaults to make this easier), and (2) running shell scripts that consolidate and wrap the Terraform commands. We strongly recommend using these scripts because they were designed to be usable, but you could also run the Terraform templates directly using the `terraform` command line tool.

### Use the Development Container for Command Line Deployments

If you are planning to deploy from your local workstation, we recommend using the VS Code development container specified in this repository. The container includes all the tools and pre-requisites, but you have to build and run the container. If you have Docker Desktop installed, then VS Code makes the rest of it easy. See the [README](../../.devcontainer/README.md) document in the `.devcontainer` folder for details.

If you want to deploy from the command line on your workstation but do not want to use the develompent container, take a look at the [`Dockerfile`](../../.devcontainer/Dockerfile) and the [`devcontainer.json`](../../.devcontainer/Dockerfile) file for examples on how to configure your environment.

## Pre-Requisites

* **Operating system:** Mac OS, Linux, or [Windows 10 with Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
  >*We developed this on Windows 10/WSL running Ubuntu 20.04*
* **Docker:** Docker Desktop or Docker CE
  >*We use [Docker Desktop on Windows 10](https://docs.docker.com/docker-for-windows/install/), integrated with WSL*
* Current version of the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).
* An Azure Subscription where you have ['Owner' RBAC permissions].

All other tools and resources are in the development container. The simplest path is to deploy from one of these containers, but it is not required if you want to configure your own deployment environment.

## Step-by-step

* Install Docker Desktop or Docker CE on a host machine. The host machine can be Windows, Linux, or Mac, and can run on-premises or in the cloud.
* Clone the Mission LZ from GitHub to a local workspace on the host machine.
  * **Recommended:** If you are using Windows for the host machine, clone and open this repository on Windows Subsystem for Linux (WSL). WSL is not required, but disk IO performance in the container is better and the overall experience is more consistent when running a development container from WSL.
    > **NOTE:** When using Windows with WSL as the host machine, we recommend the following additional steps:
    >
    > * After [installing WSL for Windows](https://docs.microsoft.com/en-us/windows/wsl/install-win10), you can run your Linux distribution path right inside PowerShell, from Windows Terminal, or in the Windows command prompt by entering `wsl.exe` or `bash.exe`. These commands will switch to a display of the Linux command line, using the path for your current directory. This path will appear to be in a mounted folder, `/mnt/c`, because we're now viewing your Windows C:\ drive folder from the Linux subsystem. You can access all of your local computer's file system from within the Linux shell by using this `/mnt/c` mounted file path.
    > * For best performance, we recommend cloning the workspace to the Linux file system. For example, from the Linux shell (as noted above), you could run:
    >
     ```BASH
          cd $HOME
          git clone https://github.com/Azure/missionlz.git
     ```
    >
    > * Authenticating to git is not required for cloning the Mission LZ repo, but you may want to set it up for times when you need authentication, like when you need to push a new branch.
    >   * The Windows Git Credential Manager can be configured to work from WSL to help with complex authentication patterns like two-factor authentication. See the [documentation here](https://docs.microsoft.com/en-us/windows/wsl/tutorials/wsl-git#git-credential-manager-setup). Below is the command to run for setting the Windows Credential Manager in WSL:
    >
     ```BASH
          git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"
     ```

## Deployment paths

* (*Optional*) For details and pre-requisites for the development container, see the [README](../../.devcontainer/README.md) document in the `.devcontainer` folder.

## Next steps

### Deploy Your Workloads

Now that you have the core hub and spoke tiers deployed (tier 0, tier 1, tier 2), the next step is to deploy one or more workload tiers. Misson LZ supports multiple workload tiers. See [Workload Deployment](workload-deployment.md) for details and step-by-step instructions.

### Manage Your Deployment

Once you have a lab deployment of Mission Landing Zone established and have decided to move forward, you will want to start planning your production deployment. We recommend reviewing the following pages during your planning phase.

* [Using Management Groups with Mission Landing Zone](management-groups.md)

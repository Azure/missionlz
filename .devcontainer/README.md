# Development Container

This folder contains configuration for a development container. Usage instructions are below. For more details see the VS Code documentation on [developing in a container](https://code.visualstudio.com/docs/remote/containers).

## How to use the remote container

All configuration related to the development container is in the `.devcontainer` directory.

- `devcontainer.json`: Configuration settings for the development container
- `Dockerfile`: Docker container definition for the development container

### Setup

- Install Docker Desktop or Docker CE on a host machine. The host machine can be Windows, Linux, or Mac, and can run on-premises or in the cloud.
- Clone the Mission LZ from GitHub to a local workspace on the host machine.
  - **Recommended:** If you are using Windows for the host machine, clone and open this repository on Windows Subsystem for Linux (WSL). WSL is not required, but disk IO performance in the container is better and the overall experience is more consistent when running a development container from WSL.
    > **NOTE:** When using Windows with WSL as the host machine, we recommend the following additional steps:
    >
    > - After [installing WSL for Windows](https://docs.microsoft.com/en-us/windows/wsl/install-win10), you can run your Linux distribution path right inside PowerShell, from Windows Terminal, or in the Windows command prompt by entering `wsl.exe` or `bash.exe`. These commands will switch to a display of the Linux command line, using the path for your current directory. This path will appear to be in a mounted folder, `/mnt/c`, because we're now viewing your Windows C:\ drive folder from the Linux subsystem. You can access all of your local computer's file system from within the Linux shell by using this `/mnt/c` mounted file path.
    > - For best performance, we recommend cloning the workspace to the Linux file system. For example, from the Linux shell (as noted above), you could run:
    >
     ```BASH
          cd $HOME
          git clone https://github.com/Azure/missionlz.git
     ```
    >
    > - The Windows Git Credential Manager can be configured to work from WSL to help with complex authentication patterns like two-factor authentication. See the [documentation here](https://docs.microsoft.com/en-us/windows/wsl/tutorials/wsl-git#git-credential-manager-setup). Below is the command to run for setting the Windows Credential Manager in WSL:

     ```BASH
          git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"
     ```

- Open a command line (e.g. `wsl.exe` or `bash.exe`), change to the root folder of the local workspace for the cloned repository, and start VS Code from this root folder (not a sub folder or a parent folder).
  > **NOTE:** If you are using WSL or BASH on Linux or Mac, you can navigate to the root folder of the project (for example, in the path `$HOME/missionlz` assuming you cloned the project to $HOME) and enter the command below to launch VS Code in correct directory. Be sure to include the trailing "." in the second command.

    ```BASH
    cd $HOME/missionlz
    code .
    ```

- Install the recommended VS Code extensions found in `.vscode/extensions.json` (relative to the root of the project folder), including the "Remote Development" extension from Microsoft.
  > **NOTE:** When VS Code starts, it reads the file `.vscode/extensions.json` relative from the current working directory. On startup, VS Code may prompt the user to install any extensions referenced here that are not already installed.

### Step-by-Step

1. Open VS Code from the root folder of the local workspace (not a sub folder or a parent folder). You should see a folder named `.devcontainer` at the root of the VS Code Explorer pane.

1. In the VS Code command palette (Ctrl+Shift+P), run this command

    ```VSCODE
    Remote-Containers: Reopen in Container
    ```

    > **NOTE:** The container will build on your machine. The first build may take several minutes; the `Reopen in Container` command will be much faster after the initial container build, and VS Code will prompt you if the container needs to be rebuilt when the `Dockerfile` or container configuration settings have changed.

    When logged into the devcontainer's terminal, the working directory changes to `vscode@missionlz-dev:/workspaces/missionlz$`

1. (*Optional*) If you'd like to interact with the devcontainer's terminal from another terminal other than VS Code's built in terminal, you can use the `docker exec` command.

    > **NOTE:** VS Code attaches to the container as the user named "vscode", so you have to do the same thing when attaching to a BASH session in the container by specifying the user as an argument to the `docker exec` command. If you do not specify the user then you will be connected as root, which will cause permissions issues in git (if you are launching VS Code from WSL).

    ```BASH
    docker exec --interactive --tty --user vscode missionlz-dev /bin/bash
    ```

    Or, the equivalent short form below:

    ```BASH
    docker exec -it -u vscode missionlz-dev /bin/bash
    ```

# Development Container

This folder contains configuration for a development container. Usage instructions are below. For more details see the VS Code documentation on [developing in a container](https://code.visualstudio.com/docs/remote/containers).

## How to use the remote container

All configuration related to the development container is in the `.devcontainer` directory.

- `devcontainer.json`: Configuration settings for the development container
- `Dockerfile`: Docker container definition for the development container

### Setup

- Install Docker Desktop or Docker CE on a host machine. The host machine can be Windows, Linux, or Mac, and can run on-premises or in the cloud.
- Recommended: If you are using Windows for the host machine, clone and open this repository on Windows Subsystem for Linux (WSL). WSL is not required, but disk IO performance in the container is better and the overall experience is more consistent when running a development container from WSL. 

    > NOTE: the Windows Git Credential Manager can be configured to work from WSL. See the [documentation here](https://docs.microsoft.com/en-us/windows/wsl/tutorials/wsl-git#git-credential-manager-setup). Below is the command to run for setting the Windows credential manager in WSL:

    ```BASH
    git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"
    ```

- Install the recommended VS Code extensions found at `../vscode/extensions.json`, including the "Remote Development" extension from Microsoft.

### Step-by-Step

1. Open VS Code to the root folder of the git repository (not a sub folder or a parent folder). You should see a folder named `.devcontainer` at the root of the VS Code Explorer pane.

    > NOTE: If you are using WSL or BASH on Linux or Mac, you can navigate to the root folder of the git repository and enter the command below to launch VS Code and open it to the right directory. Be sure to include the trailing ".".

    ```BASH
    code .
    ```

1. In the VS Code command palette (Ctrl+Shift+P), run this command

    ```VSCODE
    Remote-Containers: Reopen in Container
    ```

    The container will build on your machine. The first build may take some time; the `Reopen in Container` command will be much faster after the initial container build, and VS Code will prompt you if the container needs to be rebuilt when the `Dockerfile` or container configuration settings have changed.

1. (Optional) if you'd like to interact with the devcontainer's terminal from another terminal other than VS Code's built in terminal, you can docker's `exec` command.

    > NOTE: VS Code attaches to the container as the user named "vscode", so you have to do the same thing when attaching to a BASH session in the container by specifying the user as an argument to the `docker exec` command. If you do not specify the user then you will be connected as root, which will cause permissions issues in git (if you are launching VS Code from WSL).

    ```BASH
    docker exec --interactive --tty --user vscode missionlz-dev /bin/bash
    ```

    Or, the equivalent short form below:

    ```BASH
    docker exec -it -u vscode missionlz-dev /bin/bash
    ```

    When you are logged into the devcontainer's terminal, you will find the working directory

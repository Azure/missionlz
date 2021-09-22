# Development Container Guide

This folder contains configuration for a development container. Usage instructions are below. For more details see the VS Code documentation on [developing in a container](https://code.visualstudio.com/docs/remote/containers).

## How to use the remote container

All configuration related to the development container is in the `.devcontainer` directory.

- `devcontainer.json`: Configuration settings for the development container
- `Dockerfile`: Docker container definition for the development container

### Step-by-Step

1. Ensure you have the prerequisites installed as described here: <https://code.visualstudio.com/docs/remote/containers>

    - Windows: Docker Desktop 2.0+ on Windows 10 Pro/Enterprise. Windows 10 Home (2004+) requires Docker Desktop 2.3+ and the WSL 2 back-end. (Docker Toolbox is not supported. Windows container images are not supported.)
    - macOS: Docker Desktop 2.0+.
    - Linux: Docker CE/EE 18.06+ and Docker Compose 1.21+. (The Ubuntu snap package is not supported.)

1. Clone this repository

    ```BASH
    git clone https://github.com/Azure/missionlz
    ```

2. Change to the root folder of the local workspace for the cloned project, and start VS Code from this root folder (not a sub folder or a parent folder).

   > **NOTE:** be sure to include the trailing "." in the second command.

    ```BASH
    cd missionlz
    code .
    ```

<!-- markdownlint-disable MD013 -->
3. Install the recommended VS Code extensions found in `missionlz/.vscode/extensions.json` file. Including the "Remote Development" extension from Microsoft.

   > **NOTE:** When VS Code is correctly started from the MissionLZ project root directory, you should see folders named `.devcontainer`, `.vscode`, and `src` at the root of the VS Code Explorer pane. In the startup process, VS Code reads the file `.vscode/extensions.json` (relative from the current working directory) and may prompt the user to install any extensions referenced here that are not already installed.

<!-- markdownlint-enable MD013 -->

4. In the VS Code command palette `(Ctrl + Shift + P)`, run this command:

    ```VSCODE
    Remote-Containers: Reopen in Container
    ```

    > **NOTE:** The container will build on your machine. The first build may take several minutes; the `Reopen in Container` command will be much faster after the initial container build, and VS Code will prompt you if the container needs to be rebuilt when the `Dockerfile` or container configuration settings have changed.

    When logged into the devcontainer's terminal, the working directory changes to `vscode@missionlz-dev:/workspaces/missionlz$`

### Step-by-Step (VS Code alternative)

(*Optional*) If you'd like to interact with the devcontainer's terminal from another terminal other than VS Code's built in terminal, you can use the `docker exec` command.

 > **NOTE:** VS Code attaches to the container as the user named "vscode", so you have to do the same thing when attaching to a BASH session in the container by specifying the user as an argument to the `docker exec` command. If you do not specify the user then you will be connected as root, which will cause permissions issues in git (if you are launching VS Code from WSL).

```BASH
docker exec --interactive --tty --user vscode missionlz-dev /bin/bash
```

Or, the equivalent short form below:

```BASH
docker exec -it -u vscode missionlz-dev /bin/bash
```

### Authenticating to GitHub

Authenticating to GitHub is not required for cloning the Mission LZ repo, but you may want to set it up for times when you need authentication, like when you need to push a new branch.

The Windows Git Credential Manager can be configured to work from WSL to help with complex authentication patterns like two-factor authentication. See the [documentation here](https://docs.microsoft.com/en-us/windows/wsl/tutorials/wsl-git#git-credential-manager-setup).

For WSL, this is the command to run for configuring the Windows Credential Manager:

```BASH
git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"
```

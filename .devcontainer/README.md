# Development Container

This folder contains configuration for a development container. Usage instructions are below. For more details see the VS Code documentation on [developing in a container](https://code.visualstudio.com/docs/remote/containers).

## How to use the remote container

All configuration related to the development container is in the `.devcontainer` directory.

- `devcontainer.json`: Configuration settings for the development container
- `Dockerfile`: Docker container definition for the development container

### Step-by-Step

1. Open a command line (e.g. `wsl.exe` or `bash.exe`), change to the root folder of the cloned local workspace for the cloned Mission LZ project, and start VS Code from this root folder (not a sub folder or a parent folder).
   > **NOTE:** If you are using WSL or BASH on Linux or Mac, you can navigate to the root folder of the project (for example, in the path `$HOME/missionlz` assuming you cloned the project to $HOME) and enter the command below to launch VS Code in correct directory. Be sure to include the trailing "." in the second command.

    ```BASH
    cd $HOME/missionlz
    code .
    ```

1. Install the recommended VS Code extensions found in `.vscode/extensions.json` (relative to the root of the project folder), including the "Remote Development" extension from Microsoft.
   > **NOTE:** When VS Code is correctly started from the MissionLZ project root directory, you should see folders named `.devcontainer`, `.vscode`, and `src` at the root of the VS Code Explorer pane. In the startup process, VS Code reads the file `.vscode/extensions.json` (relative from the current working directory) and may prompt the user to install any extensions referenced here that are not already installed.

1. In the VS Code command palette (Ctrl+Shift+P), run this command:

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

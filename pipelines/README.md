# Build Pipelines

All build pipeline configurations apply to Azure DevOps pipelines. They are not specific to an Azure DevOps project. Configuration settings that are specific to a particular Azure DevOps project or container repository are stored within the Azure DevOps project settings. For example, the connection to push a container image to a registry is stored in the Azure DevOps project, and the connection name is referenced in the pipeline yaml file.

## Container Pipeline: `container-pipeline.yml`

Container image build for the development container at `.devcontainer/Dockerfile`.

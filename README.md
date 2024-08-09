# Mission LZ

[**Home**](./README.md) | [**Design**](./DESIGN.md) | [**Accelerators**](./ACCELERATORS.md) | [**Resources**](./RESOURCES.md)

Mission Landing Zone is a highly opinionated Infrastructure-as-Code (IaC) template which IT oversight organizations can use to create a cloud management system to deploy Azure environments for their workloads and teams.

Mission Landing Zone addresses a narrowly scoped, specific need for a [Secure Cloud Computing Architecture (SCCA)](docs/scca.md) compliant hub and spoke infrastructure.

- Designed for US Government mission customers
- Implements SCCA controls following Microsoft's [SACA](https://aka.ms/saca) implementation guidance
- Deployable in Azure commercial, Azure Government, Azure Government Secret, and Azure Government Top Secret clouds
- A simple solution with low configuration and narrow scope
- Written as [Bicep](./src/bicep/) and [Terraform](./src/terraform/) templates

Mission Landing Zone is the right solution when:

- A simple, secure, and scalable hub and spoke infrastructure is needed.
- A central IT team is administering cloud resources on behalf of other teams and workloads.
- There is a need to implement SCCA.
- Hosting any workload requiring a secure environment, for example: data warehousing, AI/ML, and containerized applications.

Design goals include:

- A simple, minimal set of code that is easy to configure
- Good defaults that allow experimentation and testing in a single subscription
- Deployment via command line or with a user interface
- 100% Azure PaaS products

Our intent is to enable IT Admins to use this software to:

- Test and evaluate the landing zone using a single Azure subscription
- Develop a known good configuration that can be used for production with multiple Azure subscriptions
- Customize the deployment configuration to suit specific needs
- Deploy multiple customer workloads in production

## Quickstart

You can deploy Mission Landing Zone from the Azure Portal, or by executing an Azure CLI command.

You must have [Owner RBAC permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner) to the subscription(s) you deploy Mission Landing Zone into.

### Deploy from the Azure Portal
<!-- markdownlint-disable MD013 -->
1. Deploy Mission Landing Zone into `AzureCloud` or `AzureUsGovernment` from the Azure Portal:

    | Azure Commercial | Azure Government |
    | :--- | :--- |
    | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fmlz.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fform%2Fmlz.portal.json) | [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fmlz.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fform%2Fmlz.portal.json) |
<!-- markdownlint-enable MD013 -->

2. After a successful deployment, see our [add-ons](./src/bicep/add-ons/) directory for how to extend the capabilities of Mission Landing Zone.

### Deploy using a TemplateSpec in Azure Secret or Azure Top Secret

Click [here](./docs/deployment-guide-templatespec.md) to learn how to create a templatespec.

### Walkthrough of the Azure Quickstart Mission LZ deployment template

Click [here](./docs/deployment-guide-walkthrough.md) to learn about each tab and the components of an MLZ deployment.

### Deploy using the Azure CLI

1. Clone the repository and change directory to the root of the repository:

    ```plaintext
    git clone https://github.com/Azure/missionlz.git
    cd missionlz
    ```

1. Deploy Mission Landing Zone with the [`az deployment sub create`](https://docs.microsoft.com/en-us/cli/azure/deployment/sub?view=azure-cli-latest#az_deployment_sub_create) command. For a quickstart, we suggest a test deployment into the current AZ CLI subscription setting these parameters:

    - `--name`: (optional) The deployment name, which is visible in the Azure Portal under Subscription/Deployments.
    - `--location`: (required) The Azure region to store the deployment metadata.
    - `--template-file`: (required) The file path to the `mlz.bicep` template.
    - `--parameters resourcePrefix=<value>`: (required) The `resourcePrefix` Bicep parameter is used to generate names for your resources. It is the only required parameter in the Bicep file. You can set it to any alphanumeric value (without whitespace) that is between 3-10 characters. You can omit this parameter and the `az deployment sub create` command will prompt you to enter a value.

    Here's an example:

    ```plaintext
    az deployment sub create \
    --name myMlzDeployment \
    --location eastus \
    --template-file ./src/bicep/mlz.bicep \
    --parameters resourcePrefix="myMlz"
    ```

1. After a successful deployment, see our [add-ons](./src/bicep/add-ons/) directory for how to extend the capabilities of Mission Landing Zone.

> Don't have Azure CLI? Here's how to get started with Azure Cloud Shell in your browser: <https://docs.microsoft.com/en-us/azure/cloud-shell/overview>


## Getting Started

For more detailed deployment instructions, see the [Deployment Guide for Bicep](docs/deployment-guide-bicep.md) and the [Deployment Guide for Terraform](docs/deployment-guide-terraform.md) in the [`docs`](docs) folder.

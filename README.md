# Mission Landing Zone

[**Home**](./README.md) | [**Design**](./docs/design.md) | [**Add-Ons**](./src/bicep/add-ons/README.md) | [**Resources**](./docs/resources.md)

Mission Landing Zone is a highly opinionated infrastructure as code (IaC) template. IT oversight organizations can use the template to create a cloud management system to deploy Azure environments for their workloads and teams. The solution addresses a narrowly scoped, specific need for a [Secure Cloud Computing Architecture (SCCA)](docs/scca.md) compliant hub and spoke infrastructure.

- Designed for US Government mission customers
- Implements controls following Microsoft's [SACA](https://aka.ms/saca) and [zero trust](https://learn.microsoft.com/security/zero-trust/) guidance
- Deployable in Azure Commercial, Azure Government, Azure Government Secret, and Azure Government Top Secret clouds
- A simple solution with low configuration and narrow scope
- Written as [Bicep](./src/bicep/) templates

Mission Landing Zone is the right solution when:

- A simple, secure, and scalable hub and spoke infrastructure is needed.
- A central IT team is administering cloud resources on behalf of other teams and workloads.
- There is a need to implement SCCA with zero trust.
- Hosting any workload requiring a secure environment, for example: data warehousing, AI/ML, and containerized applications.

Design goals include:

- A simple, minimal set of code that is easy to configure
- Good defaults that allow experimentation and testing in a single subscription
- Deployment via command line or with a user interface

Our intent is to enable IT Admins to use this software to:

- Test and evaluate the landing zone using a single Azure subscription
- Develop a known good configuration that can be used for production with multiple Azure subscriptions
- Customize the deployment configuration to suit specific needs
- Deploy multiple customer workloads in production.

> [!NOTE]  
> Be sure to check out our **[add-ons](./src/bicep/add-ons/README.md)** to accelerate workload deployments.

## Quickstart

Mission Landing Zone can be deployed from the Azure Portal, or with Azure command line tools.

### Prerequistes

The following prerequisites are required on the target subscription(s):

- [Owner RBAC permissions](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#owner)
- [Enable Encryption At Host](https://learn.microsoft.com/azure/virtual-machines/disks-enable-host-based-encryption-portal?tabs=azure-powershell#prerequisites)

### Deployment Options

- [Azure Portal](#deploy-from-the-azure-portal)
- [Template Spec](#deploy-using-a-templatespec-in-azure-secret-or-azure-top-secret)
- [Azure CLI](#deploy-using-the-azure-cli)

#### Deploy from the Azure Portal

Deploy Mission Landing Zone into **Azure Commercial** or **Azure Government** from the Azure Portal:

| Cloud  | Deployment Button |
| :----- | :----- |
| Azure Commercial | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fmlz.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fform%2Fmlz.portal.json) |
| Azure Government |  [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fmlz.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fform%2Fmlz.portal.json) |

> [!NOTE]
> [Click here to learn about each step and element in the user interface.](./docs/deployment-guides/walkthrough.md)

#### Deploy using a TemplateSpec in Azure Secret or Azure Top Secret

[Click here to learn how to create a templatespec.](./docs/deployment-guides/templatespec.md)

#### Deploy using the Azure CLI

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

1. Once the MLZ deployment is complete, see our [add-ons](./src/bicep/add-ons/) directory to extend the capabilities of your landing zone.

> [!NOTE]
> For more detailed deployment instructions, see the **[Deployment Guide for Bicep](./docs/deployment-guides/bicep.md)** in the **[docs](docs)** folder.

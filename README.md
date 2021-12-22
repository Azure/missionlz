# Mission LZ

Mission Landing Zone is a highly opinionated Infrastructure-as-Code (IaC) template which IT oversight organizations can use to create a cloud management system to deploy Azure environments for their workloads and teams.

Mission Landing Zone addresses a narrowly scoped, specific need for a [Secure Cloud Computing Architecture (SCCA)](docs/scca.md) compliant hub and spoke infrastructure.

- Designed for US Government mission customers
- Implements SCCA controls following Microsoft's [SACA](https://aka.ms/saca) implementation guidance
- Deployable in Azure commercial, Azure Government, Azure Government Secret, and Azure Government Top Secret clouds
- A simple solution with low configuration and narrow scope
- Written as [Bicep](./src/bicep/README.md) and [Terraform](./src/terraform/README.md) templates

Mission Landing Zone is the right solution when:

- A simple, secure, and scalable hub and spoke infrastructure is needed.
- A central IT team is adminstering cloud resources on behalf of other teams and workloads.
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

## What is a Landing Zone?

A **landing zone** is networking infrastructure configured to provide a secure environment for hosting workloads.

## Quickstart

You can deploy Mission Landing Zone from the Azure Portal or by executing an Azure CLI command.

You must have [Owner RBAC permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner) to the subscription(s) you deploy Mission Landing Zone into.

### Deploy from the Azure Portal
<!-- markdownlint-disable MD013 -->
1. Deploy Mission Landing Zone into `AzureCloud` or `AzureUsGovernment` from the Azure Portal:

    | Azure Commercial | Azure Government |
    | :--- | :--- |
    | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fmlz.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fform%2Fmlz.portal.json) | [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fmlz.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fform%2Fmlz.portal.json) |
<!-- markdownlint-enable MD013 -->

2. After a successful deployment, see our [examples](./src/bicep/examples/README.md) directory for how to extend the capabilities of Mission Landing Zone.

### Deploy using the Azure CLI

> Don't have Azure CLI? Here's how to get started with Azure Cloud Shell in your browser: <https://docs.microsoft.com/en-us/azure/cloud-shell/overview>

1. Clone the repository and change directory to the root of the repository:

    ```plaintext
    git clone https://github.com/Azure/missionlz.git
    cd missionlz
    ```

1. Deploy Mission Landing Zone with the [`az deployment sub create`](https://docs.microsoft.com/en-us/cli/azure/deployment/sub?view=azure-cli-latest#az_deployment_sub_create) command. For a quickstart test deployment into a single subscription we suggest setting these parameters, which will deploy MLZ into the current AZ CLI subscription:

    - `--name`: (optional) The deployment name, which is visible in the Azure Portal under Subscription/Deployments.
    - `--location`: (required) The location to store the deployment metadata.
    - `--template-file`: (required) The file path to the `mlz.bicep` template.
    - `--parameters resourcePrefix=<value>`: (required) The `resourcePrefix` Bicep parameter is used to generate names for your resources. It is the only required parameter in the Bicep file. You can set it to any alphanumeric value that is between 3-10 characters. You can omit this parameter and the `az deployment sub create` command will prompt you to enter a value.

    ```plaintext
    az deployment sub create \
    --name myMlzDeployment \
    --location eastus \
    --template-file ./src/bicep/mlz.bicep \
    --parameters resourcePrefix="myMlz"
    ```

1. After a successful deployment, see our [examples](./src/bicep/examples/README.md) directory for how to extend the capabilities of Mission Landing Zone.

## Scope

Mission LZ has the following scope:

- Hub and spoke networking intended to comply with SCCA controls
- Predefined spokes for identity, operations, shared services, and workloads
- Ability to create multiple, isolated workloads or team subscriptions
- Remote access
- Compatibility with SCCA compliance (and other compliance frameworks)
- Security using standard Azure tools with sensible defaults
- Azure Policy initiatives

<!-- markdownlint-disable MD033 -->
<!-- allow html for images so that they can be sized -->
<img src="docs/images/scope-v2.png" alt="Mission LZ Scope" width="600" />
<!-- markdownlint-enable MD033 -->

## Networking

Networking is set up in a hub and spoke design, separated by tiers: T0 (Identity and Authorization), T1 (Infrastructure Operations), T2 (DevSecOps and Shared Services), and multiple T3s (Workloads). Access control can be configured to allow separation of duties between all tiers.

<!-- markdownlint-disable MD033 -->
<!-- allow html for images so that they can be sized -->
<img src="docs/images/networking.png" alt="Mission LZ Networking" width="600" />
<!-- markdownlint-enable MD033 -->

## Subscriptions

Most customers will deploy each tier to a separate Azure subscription, but multiple subscriptions are not required. A single subscription deployment is good for a small IT Admin team, or for testing and evaluation.

## Firewall

All network traffic is directed through the firewall residing in the Network Hub resource group. The firewall is configured as the default route for all the T0 (Identity and Authorization) through T3 (workload/team environments) resource groups as follows:  

|Name         |Address prefix| Next hop type| Next hop IP address|
|-------------|--------------|-----------------|-----------------|
|default_route| 0.0.0.0/0    |Virtual Appliance|10.0.100.4       |

The default firewall configured for MLZ is [Azure Firewall Premium](https://docs.microsoft.com/en-us/azure/firewall/premium-features).

Presently, there are two firewall rules configured to ensure access to the Azure Portal and to facilitate interactive logon via PowerShell and Azure CLI, all other traffic is restricted by default. Below are the collection of rules configured for Azure Commercial and Azure Government clouds:

|Rule Collection Priority | Rule Collection Name | Rule name | Source | Port     | Protocol                               |
|-------------------------|----------------------|-----------|--------|----------|----------------------------------------|
|100                      | AllowAzureCloud      | AzureCloud|*       |   *      |Any                                     |
|110                      | AzureAuth            | msftauth  |  *     | Https:443| aadcdn.msftauth.net, aadcdn.msauth.net |

## Getting Started using Mission LZ

See our [Getting Started Guide](docs/getting-started.md) in the docs.

## Product Roadmap

See the [Projects](https://github.com/Azure/missionlz/projects) page for the release timeline and feature areas.

Here's a summary of what Mission Landing Zone deploys of as of December 2021:

<!-- markdownlint-disable MD033 -->
<!-- allow html for images so that they can be sized -->
<img src="docs/images/20211220_missionlz_as_of_Dec2021.svg" alt="Mission LZ as of December 2021" width="1200" />
<!-- markdownlint-enable MD033 -->

## Contributing

This project welcomes contributions and suggestions. See our [Contributing Guide](CONTRIBUTING.md) for details.

## Feedback, Support, and How to Contact Us

Please see the [Support and Feedback Guide](SUPPORT.md). To report a security issue please see our [security guidance](./SECURITY.md).

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.

## Nightly Build Status

<!-- markdownlint-disable MD033 -->
|Deployment Type|Azure Cloud| Azure Government|
|-------------|--------------|-----------------|
|Bicep| [![Build Status](https://ag-ascii.visualstudio.com/Mission%20Landing%20Zone%20-%20Pipeline/_apis/build/status/mlz-nightly/mlz-bicep-azurecloud-nightly?branchName=main)](https://ag-ascii.visualstudio.com/Mission%20Landing%20Zone%20-%20Pipeline/_build/latest?definitionId=164&branchName=main)|[![Build Status](https://ag-ascii.visualstudio.com/Mission%20Landing%20Zone%20-%20Pipeline/_apis/build/status/mlz-nightly/mlz-bicep-azuregov-nightly?branchName=main)](https://ag-ascii.visualstudio.com/Mission%20Landing%20Zone%20-%20Pipeline/_build/latest?definitionId=165&branchName=main)|
|Terraform| [![Build Status](https://ag-ascii.visualstudio.com/Mission%20Landing%20Zone%20-%20Pipeline/_apis/build/status/mlz-nightly/mlz-tf-azurecloud-nightly?branchName=main)](https://ag-ascii.visualstudio.com/Mission%20Landing%20Zone%20-%20Pipeline/_build/latest?definitionId=166&branchName=main) |[![Build Status](https://ag-ascii.visualstudio.com/Mission%20Landing%20Zone%20-%20Pipeline/_apis/build/status/mlz-nightly/mlz-tf-azuregov-nightly?branchName=main)](https://ag-ascii.visualstudio.com/Mission%20Landing%20Zone%20-%20Pipeline/_build/latest?definitionId=167&branchName=main)
<!-- markdownlint-enable MD033 -->

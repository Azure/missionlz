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

## Deployment Options

Mission Landing Zone can be deployed from the Azure Portal, or with Azure command line tools. Choose the desired option below for detailed deployment documentation.

| Method | Supported Clouds |
| :----- | :--------------- |
| [Azure Portal](./docs/deployment-guides/portal.md) | Azure Commercial, Azure Government |
| [Template Spec](./docs/deployment-guides/template-spec.md) | Azure Commercial, Azure Government, Azure Government Secret, & Azure Government Top Secret |
| [Command Line Tools](./docs/deployment-guides/command-line-tools.md)  | Azure Commercial, Azure Government, Azure Government Secret, & Azure Government Top Secret |

> [!NOTE]  
> Be sure to check out our **[add-ons](./src/bicep/add-ons/README.md)** to accelerate workload deployments.

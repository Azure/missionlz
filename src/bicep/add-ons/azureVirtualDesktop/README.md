# Azure Virtual Desktop Solution

[**Home**](./README.md) | [**Features**](./docs/features.md) | [**Design**](./docs/design.md) | [**Prerequisites**](./docs/prerequisites.md) | [**Troubleshooting**](./docs/troubleshooting.md)

This solution will deploy a fully operational Azure Virtual Desktop (AVD) [stamp](https://learn.microsoft.com/azure/architecture/patterns/deployment-stamp) adhereing to the [Zero Trust principles](https://learn.microsoft.com/security/zero-trust/azure-infrastructure-avd). Many of the [common features](./docs/features.md) used with AVD have been automated in this solution for your convenience.

# Deployment Options

## Deploy with Bicep in Azure cli

> [!WARNING]
> Failure to complete the [prerequisites](./docs/prerequisites.md) will result in an unsuccessful deployment.

1. Complete the [prerequisites](./docs/prerequisites.md)
1. Execute AVD Bicep deployment

### Execute AVD Bicep deployment in Azure cli

1. Update the parameter file with resource names and settings for the target environment
1. Execute the ```az deployment``` command by passing the parameter file, and the main Bicep file
1. Verify resources are created and provisioned according to the specified template and parameters
1. Test access to an AVD session from a Remote Desktop Client

#### Update the parameter file

{{ list of parameters, and what they are, and their options }}
{{ what values and settings are we using for this specific customer }}

**Examples from Solutions.json**  

Some of the example Parameters from Solution.json file. [solution.json](solution.json) 

*Domain services* 

Description: The service providing domain services for Azure Virtual Desktop.  This is needed to properly configure the session hosts and if applicable, the Azure Storage Account. 

Please provide string value for 'activeDirectorySolution' 

- [1] ActiveDirectoryDomainServices 
- [2] MicrosoftEntraDomainServices 
- [3] MicrosoftEntraId 
- [4] MicrosoftEntraIdIntuneEnrollment 

Note: Default choice (1) 

*Azure Blobs container*  

Description: The name of the Azure Blobs container hosting the required artifacts 
Please provide string value for 'artifactsContainerName': 

*Note:* First, create an Azure Storage Account. Next, set up a container. Retrieve all the artifacts from the repository  from the path missionlz/src/bicep/add-ons/azureVirtualDesktop/artifacts at main · Azure/missionlz (github.com), and finally, upload them into your container 

*Storage account Resource* 

Description: The resource ID for the storage account hosting the artifacts in Blob storage. 

    Please provide string value for 'artifactsStorageAccountResourceId': 

*Availability zones*  

Description: The desired availability option when deploying a pooled host pool. The best practice is to deploy to availability zones for the highest resilency and service level agreement. 

    Hidden with default value: 'Availability': 

    - AvailabilitySets, 
    - AvailabilityZones, 
    - None 

    DefaultValue: "AvailabilityZones" 
  
*AVD Agent installer* 

Description: The blob name of the MSI file for the AVD Agent installer. The file must be hosted in an Azure Blobs container with the other deployment artifacts 

    Please provide string value for 'avdAgentMsiname': 

*AVD Agent Boot Loader installer* 

Description: The blob name of the MSI file for the AVD Agent Boot Loader installer. The file must be hosted in an Azure Blobs container with the other deployment artifacts. 

    Please provide string value for 'avdAgentBootLoaderMsiName': 

*Entra ID object ID*  

Description: The object ID for the Azure Virtual Desktop enterprise application in Microsoft Entra ID.  The object ID can found by selecting Microsoft Applications using the Application type filter in the Enterprise Applications blade of Microsoft Entra ID. 

    Please provide string value for 'avdObjectId': 

*Azure NetApp subnet address* 

Description: The subnet address prefix for the Azure NetApp Files delegated subnet. 

    Hidden with default value: 'azureNetAppFilesSubnetAddressPrefix' 

    DefaultValue: "" 

          

*Blob name of the MSI file* 

Descriptions: The blob name of the MSI file for the  Azure PowerShell Module installer. The file must be hosted in an Azure Blobs container with the other deployment artifacts. 

    Please provide string vaule for 'azurePowerShellModuleMsiName': 

*RDP properties*  

Description: The RDP properties to add or remove RDP functionality on the AVD host pool. The string must end with a semi-colon. 

    Hidden with default value: 'customRdpProperty' 

    DefaultValue: "audiocapturemode:i:1;camerastoredirect:s:*;use multimon:i:0;drivestoredirect:s:;encode redirected video capture:i:1;redirected video capture encoding quality:i:1;audiomode:i:0;devicestoredirect:s:;redirectclipboard:i:0;redirectcomports:i:0;redirectlocation:i:1;redirectprinters:i:0;redirectsmartcards:i:1;redirectwebauthn:i:1;usbdevicestoredirect:s:;keyboardhook:i:2;" 

          
Settings reference: https://learn.microsoft.com/windows-server/remote/remote-desktop-services/clients/rdp-files 

*Host pool IP* 

Description: The type of public network access for the host pool. 

    Please provide string value for 'hostPoolPublicNetworkAccess' 

#### Execute az deployment

**Deployment name** 

When deploying a Bicep file, you can give the deployment a name. This name can help you retrieve the deployment from the deployment history. If you don't provide a name for the deployment, the name of the Bicep file is used. For example, if you deploy a Bicep file named main.bicep and don't specify a deployment name, the deployment is named main. 

Every time you run a deployment, an entry is added to the resource group's deployment history with the deployment name. If you run another deployment and give it the same name, the earlier entry is replaced with the current deployment. If you want to maintain unique entries in the deployment history, give each deployment a unique name. 

To create a unique name, you can assign a random number. 

    deploymentName='ExampleDeployment'$RANDOM 

Or, add a date value. 

    deploymentName='ExampleDeployment'$(date +"%d-%b-%Y") 

**Deploy local Bicep file** 

1. Login to Azure Portal 
1. Open bash shell in Azure Cloud Shell 
1. Run the following command 
    ```bash
    az deployment sub create –name <deployment-name>  –location <location> --template-file <path-to-bicep-file> --parameters @<path-to-parameter-file>
    ```

    Where  

        <deployment-name> = is the name of your deployment so you can view the deployment recorded results in Azure 
        <location> = one of the Azure gov locations 
        <path-to-bicep-file> = where the solution.json file is located 
        <path-to-parameter-file> = where the parameter file is located 

The deployment can take a few minutes to complete. When it finishes, you see a message that includes the result: 
    
    "provisioningState": "Succeeded", 

#### Verify deployment

- Run the az deployment command to see the status 
```az deployment sub show --name <deployment-name> --query properties.provisioningState ```
- Get the output of the deployment and the state of the resources 
```az deployment sub show --name <deployment-name> --query properties.outputs ```

#### Perform Testing

- Open a Remote Desktop Client to verify a user can successfully access an AVD session

## Other Options

> [!ATTENTION]
> Not using any of the following options for this customer!

### Blue Buttons (<<--We are NOT doing this option)

This option opens the deployment UI for the solution in the Azure Portal. Be sure to select the button for the correct cloud. If your desired cloud is not listed, please use the template spec option below.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2FazureVirtualDesktop%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2FazureVirtualDesktop%2FuiDefinition.json)
[![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2FazureVirtualDesktop%2Fsolution.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fmissionlz%2Fmain%2Fsrc%2Fbicep%2Fadd-ons%2FazureVirtualDesktop%2FuiDefinition.json)

### Template Spec

This option creates a template spec in Azure to deploy the solution and is the preferred option for air-gapped clouds. Once you create the template spec, open it in the portal and click the "Deploy" button.

````powershell
$Location = '<Azure Location>'
$ResourceGroupName = 'rg-ts-<Environment Abbreviation>-<Location Abbreviation>'
$TemplateSpecName = 'ts-avd-<Environment Abbreviation>-<Location Abbreviation>'

New-AzResourceGroup `
    -Name $ResourceGroupName `
    -Location $Location `
    -Force

New-AzTemplateSpec `
    -ResourceGroupName $ResourceGroupName `
    -Name $TemplateSpecName `
    -Version 1.0 `
    -Location $Location `
    -TemplateFile '.\src\bicep\add-ons\azureVirtualDesktop\solution.json' `
    -UIFormDefinitionFile '.\src\bicep\add-ons\azureVirtualDesktop\uiDefinition.json' `
    -Force
````

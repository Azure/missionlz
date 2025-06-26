param 
(
    [String]$ActiveDirectorySolution,
    [String]$DomainJoinPassword,
    [String]$DomainJoinUserPrincipalName,
    [String]$FileShares,
    [String]$Netbios,
    [String]$OrganizationalUnitPath,
    [string]$ResourceManagerUri,
    [String]$SecurityPrincipalNames,
    [String]$SmbServerNamePrefix,
    [String]$StorageAccountPrefix,
    [String]$StorageAccountResourceGroupName,
    [Int]$StorageCount,
    [Int]$StorageIndex,
    [String]$StorageService,
    [String]$StorageSuffix,
    [String]$SubscriptionId,
    [String]$UserAssignedIdentityClientId
)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

##############################################################
#  Install Active Directory PowerShell module
##############################################################
if($StorageService -eq 'AzureNetAppFiles' -or ($StorageService -eq 'AzureFiles' -and $ActiveDirectorySolution -eq 'ActiveDirectoryDomainServices'))
{
    $RsatInstalled = (Get-WindowsFeature -Name 'RSAT-AD-PowerShell').Installed
    if(!$RsatInstalled)
    {
        Install-WindowsFeature -Name 'RSAT-AD-PowerShell' | Out-Null
    }
}


##############################################################
#  Variables
##############################################################
# Convert parameters values from JSON array to a PowerShell array
[array]$SecurityPrincipalNames = $SecurityPrincipalNames.Replace('\','') | ConvertFrom-Json
[array]$Shares = $FileShares.Replace('\','') | ConvertFrom-Json

if($StorageService -eq 'AzureNetAppFiles' -or ($StorageService -eq 'AzureFiles' -and $ActiveDirectorySolution -eq 'ActiveDirectoryDomainServices'))
{
    # Create Domain credential
    $DomainUsername = $DomainJoinUserPrincipalName
    $DomainPassword = ConvertTo-SecureString -String $DomainJoinPassword -AsPlainText -Force
    [pscredential]$DomainCredential = New-Object System.Management.Automation.PSCredential ($DomainUsername, $DomainPassword)

    # Get Domain information
    $Domain = Get-ADDomain -Credential $DomainCredential -Current 'LocalComputer'
}

if($StorageService -eq 'AzureFiles')
{
    $FilesSuffix = '.file.' + $StorageSuffix

    # Fix the resource manager URI since only AzureCloud contains a trailing slash
    $ResourceManagerUriFixed = if ($ResourceManagerUri[-1] -eq '/') { $ResourceManagerUri.Substring(0, $ResourceManagerUri.Length - 1) } else { $ResourceManagerUri }

    # Get an access token for Azure resources
    $AzureManagementAccessToken = (Invoke-RestMethod `
        -Headers @{Metadata = "true" } `
        -Uri $('http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=' + $ResourceManagerUriFixed + '&client_id=' + $UserAssignedIdentityClientId)).access_token

    # Set header for Azure Management API
    $AzureManagementHeader = @{
        'Content-Type'  = 'application/json'
        'Authorization' = 'Bearer ' + $AzureManagementAccessToken
    }
}


##############################################################
#  Process Storage Resources
##############################################################
for($i = 0; $i -lt $StorageCount; $i++)
{
    # Determine Principal for assignment
    $SecurityPrincipalName = $SecurityPrincipalNames[$i]
    $Group = $Netbios + '\' + $SecurityPrincipalName

    # Get storage resource details
    switch($StorageService)
    {
        'AzureNetAppFiles' {
            $Credential = $DomainCredential
            $SmbServerName = (Get-ADComputer -Filter "Name -like '$SmbServerNamePrefix*'" -Credential $DomainCredential).Name
            $FileServer = '\\' + $SmbServerName + '.' + $Domain.DNSRoot
        }
        'AzureFiles' {
            $StorageAccountName = $($StorageAccountPrefix + ($i + $StorageIndex).ToString().PadLeft(2,'0')).Substring(0,15)
            $FileServer = '\\' + $StorageAccountName + $FilesSuffix

            # Get the storage account key
            $StorageKey = (Invoke-RestMethod `
                -Headers $AzureManagementHeader `
                -Method 'POST' `
                -Uri $($ResourceManagerUriFixed + '/subscriptions/' + $SubscriptionId + '/resourceGroups/' + $StorageAccountResourceGroupName + '/providers/Microsoft.Storage/storageAccounts/' + $StorageAccountName + '/listKeys?api-version=2023-05-01')).keys[0].value

            # Create credential for accessing the storage account
            $StorageUsername = 'Azure\' + $StorageAccountName
            $StoragePassword = ConvertTo-SecureString -String "$($StorageKey)" -AsPlainText -Force
            [pscredential]$StorageKeyCredential = New-Object System.Management.Automation.PSCredential ($StorageUsername, $StoragePassword)
            $Credential = $StorageKeyCredential

            if($ActiveDirectorySolution -eq 'ActiveDirectoryDomainServices')
            {
                # Get / create kerberos key for Azure Storage Account
                $KerberosKey = ((Invoke-RestMethod `
                    -Headers $AzureManagementHeader `
                    -Method 'POST' `
                    -Uri $($ResourceManagerUriFixed + '/subscriptions/' + $SubscriptionId + '/resourceGroups/' + $StorageAccountResourceGroupName + '/providers/Microsoft.Storage/storageAccounts/' + $StorageAccountName + '/listKeys?api-version=2023-05-01&$expand=kerb')).keys | Where-Object { $_.Keyname -contains 'kerb1' }).Value
                
                if (!$KerberosKey) 
                {
                    Invoke-RestMethod `
                        -Body (@{keyName = 'kerb1' } | ConvertTo-Json) `
                        -Headers $AzureManagementHeader `
                        -Method 'POST' `
                        -Uri $($ResourceManagerUriFixed + '/subscriptions/' + $SubscriptionId + '/resourceGroups/' + $StorageAccountResourceGroupName + '/providers/Microsoft.Storage/storageAccounts/' + $StorageAccountName + '/regenerateKey?api-version=2023-05-01')
                    
                    $Key = ((Invoke-RestMethod `
                        -Headers $AzureManagementHeader `
                        -Method 'POST' `
                        -Uri $($ResourceManagerUriFixed + '/subscriptions/' + $SubscriptionId + '/resourceGroups/' + $StorageAccountResourceGroupName + '/providers/Microsoft.Storage/storageAccounts/' + $StorageAccountName + '/listKeys?api-version=2023-05-01&$expand=kerb')).keys | Where-Object { $_.Keyname -contains 'kerb1' }).Value
                } 
                else 
                {
                    $Key = $KerberosKey
                }

                # Creates a password for the Azure Storage Account in AD using the Kerberos key
                $ComputerPassword = ConvertTo-SecureString -String $Key.Replace("'","") -AsPlainText -Force

                # Create the SPN value for the Azure Storage Account; attribute for computer object in AD 
                $SPN = 'cifs/' + $StorageAccountName + $FilesSuffix

                # Create the Description value for the Azure Storage Account; attribute for computer object in AD 
                $Description = "Computer account object for Azure storage account $($StorageAccountName)."

                # Create the AD computer object for the Azure Storage Account
                $Computer = Get-ADComputer -Credential $DomainCredential -Filter {Name -eq $StorageAccountName}
                if($Computer)
                {
                    Remove-ADComputer -Credential $DomainCredential -Identity $StorageAccountName -Confirm:$false
                }
                $ComputerObject = New-ADComputer -Credential $DomainCredential -Name $StorageAccountName -Path $OrganizationalUnitPath -ServicePrincipalNames $SPN -AccountPassword $ComputerPassword -Description $Description -PassThru

                $Body = (@{
                    properties = @{
                        azureFilesIdentityBasedAuthentication = @{
                            activeDirectoryProperties = @{
                                accountType = 'Computer'
                                azureStorageSid = $ComputerObject.SID.Value
                                domainGuid = $Domain.ObjectGUID.Guid
                                domainName = $Domain.DNSRoot
                                domainSid = $Domain.DomainSID.Value
                                forestName = $Domain.Forest
                                netBiosDomainName = $Domain.NetBIOSName
                                samAccountName = $StorageAccountName
                            }
                            directoryServiceOptions = 'AD'
                        }
                    }
                } | ConvertTo-Json -Depth 6 -Compress)

                Invoke-RestMethod `
                    -Body $Body `
                    -Headers $AzureManagementHeader `
                    -Method 'PATCH' `
                    -Uri $($ResourceManagerUriFixed + '/subscriptions/' + $SubscriptionId + '/resourceGroups/' + $StorageAccountResourceGroupName + '/providers/Microsoft.Storage/storageAccounts/' + $StorageAccountName + '?api-version=2023-05-01')
        
                # Set the Kerberos encryption on the computer object
                $DistinguishedName = 'CN=' + $StorageAccountName + ',' + $OrganizationalUnitPath
                Set-ADComputer -Credential $DomainCredential -Identity $DistinguishedName -KerberosEncryptionType 'AES256' | Out-Null
                
                # Reset the Kerberos key on the Storage Account
                Invoke-RestMethod `
                    -Body (@{keyName = 'kerb1' } | ConvertTo-Json) `
                    -Headers $AzureManagementHeader `
                    -Method 'POST' `
                    -Uri $($ResourceManagerUriFixed + '/subscriptions/' + $SubscriptionId + '/resourceGroups/' + $StorageAccountResourceGroupName + '/providers/Microsoft.Storage/storageAccounts/' + $StorageAccountName + '/regenerateKey?api-version=2023-05-01')
                
                $Key = ((Invoke-RestMethod `
                    -Headers $AzureManagementHeader `
                    -Method 'POST' `
                    -Uri $($ResourceManagerUriFixed + '/subscriptions/' + $SubscriptionId + '/resourceGroups/' + $StorageAccountResourceGroupName + '/providers/Microsoft.Storage/storageAccounts/' + $StorageAccountName + '/listKeys?api-version=2023-05-01&$expand=kerb')).keys | Where-Object { $_.Keyname -contains 'kerb1' }).Value
        
                # Update the password on the computer object with the new Kerberos key on the Storage Account
                $NewPassword = ConvertTo-SecureString -String $Key -AsPlainText -Force
                Set-ADAccountPassword -Credential $DomainCredential -Identity $DistinguishedName -Reset -NewPassword $NewPassword | Out-Null
            }
        }
    }
    
    foreach($Share in $Shares)
    {
        # Mount file share
        $FileShare = $FileServer + '\' + $Share
        New-PSDrive -Name 'Z' -PSProvider 'FileSystem' -Root $FileShare -Credential $Credential | Out-Null

        # Set recommended NTFS permissions on the file share
        $ACL = Get-Acl -Path 'Z:'
        $CreatorOwner = New-Object System.Security.Principal.Ntaccount ("Creator Owner")
        $ACL.PurgeAccessRules($CreatorOwner)
        $AuthenticatedUsers = New-Object System.Security.Principal.Ntaccount ("Authenticated Users")
        $ACL.PurgeAccessRules($AuthenticatedUsers)
        $Users = New-Object System.Security.Principal.Ntaccount ("Users")
        $ACL.PurgeAccessRules($Users)
        $DomainUsers = New-Object System.Security.AccessControl.FileSystemAccessRule("$Group","Modify","None","None","Allow")
        $ACL.SetAccessRule($DomainUsers)
        $CreatorOwner = New-Object System.Security.AccessControl.FileSystemAccessRule("Creator Owner","Modify","ContainerInherit,ObjectInherit","InheritOnly","Allow")
        $ACL.AddAccessRule($CreatorOwner)
        $ACL | Set-Acl -Path 'Z:' | Out-Null

        # Unmount file share
        Remove-PSDrive -Name 'Z' -PSProvider 'FileSystem' -Force | Out-Null
        Start-Sleep -Seconds 5 | Out-Null
    }
}
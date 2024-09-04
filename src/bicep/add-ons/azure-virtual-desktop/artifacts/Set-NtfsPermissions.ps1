param 
(
    [Parameter(Mandatory=$false)]
    [String]$ActiveDirectorySolution,

    [Parameter(Mandatory=$false)]
    [String]$DomainAccountType = "ComputerAccount",

    [Parameter(Mandatory)]
    [String]$DomainJoinPassword,

    [Parameter(Mandatory)]
    [String]$DomainJoinUserPrincipalName,

    [Parameter(Mandatory=$false)]
    [String]$Environment,

    [Parameter(Mandatory)]
    [String]$FslogixContainerType,

    [Parameter(Mandatory=$false)]
    [String]$Netbios,

    [Parameter(Mandatory=$false)]
    [String]$OrganizationalUnitPath,

    [Parameter(Mandatory=$false)]
    [String]$ResourceNameSuffix,

    [Parameter(Mandatory)]
    [String]$SecurityPrincipalNames,

    [Parameter(Mandatory=$false)]
    [String]$SmbServerLocation,

    [Parameter(Mandatory=$false)]
    [String]$StorageAccountPrefix,

    [Parameter(Mandatory=$false)]
    [String]$StorageAccountResourceGroupName,

    [Parameter(Mandatory=$false)]
    [Int]$StorageCount,

    [Parameter(Mandatory=$false)]
    [Int]$StorageIndex,

    [Parameter(Mandatory)]
    [String]$StorageService,

    [Parameter(Mandatory=$false)]
    [String]$StorageSuffix,

    [Parameter(Mandatory=$false)]
    [String]$SubscriptionId,

    [Parameter(Mandatory=$false)]
    [String]$TenantId,

    [parameter(Mandatory)]
    [string]
    $UniqueToken,

    [Parameter(Mandatory=$false)]
    [String]$UserAssignedIdentityClientId
)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

try 
{
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
    # Convert Security Principal Names from a JSON array to a PowerShell array
    [array]$SecurityPrincipalNames = $SecurityPrincipalNames.Replace("'",'"') | ConvertFrom-Json
    $SecurityPrincipalNames | Add-Content -Path 'C:\cse.txt' -Force | Out-Null

    # Selects the appropraite share names based on the FslogixContainerType param from the deployment
    $Shares = switch($FslogixContainerType)
    {
        'CloudCacheProfileContainer' {@('profile-containers')}
        'CloudCacheProfileOfficeContainer' {@('office-containers','profile-containers')}
        'ProfileContainer' {@('profile-containers')}
        'ProfileOfficeContainer' {@('office-containers','profile-containers')}
    }

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
                $SmbServerName = (Get-ADComputer -Filter "Name -like 'anf-$SmbServerLocation*'" -Credential $DomainCredential).Name
                $FileServer = '\\' + $SmbServerName + '.' + $Domain.DNSRoot
            }
            'AzureFiles' {
                $StorageAccountName = $($StorageAccountPrefix + ($i + $StorageIndex).ToString().PadLeft(2,'0') + $UniqueToken).Substring(0,24)
                $FileServer = '\\' + $StorageAccountName + $FilesSuffix

                # Connects to Azure using a User Assigned Managed Identity
                Connect-AzAccount -Identity -AccountId $UserAssignedIdentityClientId -Environment $Environment -Tenant $TenantId -Subscription $SubscriptionId | Out-Null

                # Get the storage account key
                $StorageKey = (Get-AzStorageAccountKey -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName)[0].Value

                # Create credential for accessing the storage account
                $StorageUsername = 'Azure\' + $StorageAccountName
                $StoragePassword = ConvertTo-SecureString -String "$($StorageKey)" -AsPlainText -Force
                [pscredential]$StorageKeyCredential = New-Object System.Management.Automation.PSCredential ($StorageUsername, $StoragePassword)
                $Credential = $StorageKeyCredential

                if($ActiveDirectorySolution -eq 'ActiveDirectoryDomainServices')
                {
                    # Get / create kerberos key for Azure Storage Account
                    $KerberosKey = (Get-AzStorageAccountKey -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName -ListKerbKey | Where-Object {$_.Keyname -contains 'kerb1'}).Value
                    if(!$KerberosKey)
                    {
                        New-AzStorageAccountKey -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName -KeyName kerb1 | Out-Null
                        $Key = (Get-AzStorageAccountKey -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName -ListKerbKey | Where-Object {$_.Keyname -contains 'kerb1'}).Value
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

                    Set-AzStorageAccount `
                        -ResourceGroupName $StorageAccountResourceGroupName `
                        -Name $StorageAccountName `
                        -EnableActiveDirectoryDomainServicesForFile $true `
                        -ActiveDirectoryDomainName $Domain.DNSRoot `
                        -ActiveDirectoryNetBiosDomainName $Domain.NetBIOSName `
                        -ActiveDirectoryForestName $Domain.Forest `
                        -ActiveDirectoryDomainGuid $Domain.ObjectGUID `
                        -ActiveDirectoryDomainsid $Domain.DomainSID `
                        -ActiveDirectoryAzureStorageSid $ComputerObject.SID.Value `
                        -ActiveDirectorySamAccountName $StorageAccountName `
                        -ActiveDirectoryAccountType 'Computer' | Out-Null
                
                    # Set the Kerberos encryption on the computer object
                    $DistinguishedName = 'CN=' + $StorageAccountName + ',' + $OrganizationalUnitPath
                    Set-ADComputer -Credential $DomainCredential -Identity $DistinguishedName -KerberosEncryptionType 'AES256' | Out-Null
                    
                    # Reset the Kerberos key on the Storage Account
                    New-AzStorageAccountKey -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName -KeyName kerb1 | Out-Null
                    $Key = (Get-AzStorageAccountKey -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName -ListKerbKey | Where-Object {$_.Keyname -contains 'kerb1'}).Value
                
                    # Update the password on the computer object with the new Kerberos key on the Storage Account
                    $NewPassword = ConvertTo-SecureString -String $Key -AsPlainText -Force
                    Set-ADAccountPassword -Credential $DomainCredential -Identity $DistinguishedName -Reset -NewPassword $NewPassword | Out-Null
                }
                Disconnect-AzAccount | Out-Null
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
    $Output = [pscustomobject][ordered]@{
        shares = $Shares
    }
    $JsonOutput = $Output | ConvertTo-Json
    return $JsonOutput
}
catch {
    $ErrorData = $_ | Select-Object *
    $ErrorData | Out-File -FilePath 'C:\cse.txt' -Append
    throw
}
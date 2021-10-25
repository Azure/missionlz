# Dev team notes

## Repo notes

- Synced fork from Azure/missionlz.git main on 10/25/2021
- Copied src/bicep folder into src/stack folder
- All development should be done against the src/stack folder

## Connection to dev Stack environment

When connecting to the Azure Stack stamp we have for development, use the command below. FYI, the caret line continuation character is for running
the command in a Windows CMD window once Azure CLI is installed

```CMD
az cloud register -n ASCIIStack ^
--endpoint-resource-manager "https://management.3173r03b.azcatcpec.com" ^
--suffix-storage-endpoint "3173r03b.azcatcpec.com" ^
--suffix-keyvault-dns ".vault.3173r03b.azcatcpec.com" ^
--endpoint-vm-image-alias-doc https://raw.githubusercontent.com/Azure/azure-rest-api-specs/master/arm-compute/quickstart-templates/aliases.json
```

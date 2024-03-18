[CmdletBinding(SupportsShouldProcess)]
param (
	[Parameter(Mandatory)]
	[string]$TemplateSpecName,

    [Parameter(Mandatory)]
	[string]$Location,

    [Parameter(Mandatory)]
	[string]$ResourceGroupName
)

New-AzTemplateSpec `
    -Name $TemplateSpecName `
    -ResourceGroupName $ResourceGroupName `
    -Version '1.0' `
    -Location $Location `
    -DisplayName "Zero Trust Image Template" `
    -TemplateFile '.\solution.json' `
    -UIFormDefinitionFile '.\uiDefinition.json' `
    -Force
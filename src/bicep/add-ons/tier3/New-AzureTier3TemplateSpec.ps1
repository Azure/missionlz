[CmdletBinding(SupportsShouldProcess)]
param (
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
    -DisplayName "Mission Landing Zone - Tier 3 Workload Environment" `
    -TemplateFile '.\solution.json' `
    -UIFormDefinitionFile '.\uiDefinition.json' `
    -Force
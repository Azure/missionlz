[CmdletBinding(SupportsShouldProcess)]
param (
	[string]$TemplateSpecName ="TIER3",

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
    -UIFormDefinitionFile 'C:\git\button\missionlz\src\bicep\add-ons\tier3\uiDefinition.json' `
    -Force
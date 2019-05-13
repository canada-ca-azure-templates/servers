Param(
    [Parameter(Mandatory = $false)][string]$templateLibraryName = "servers",
    [string]$templateName = "azuredeploy.json",
    [string]$Location = "canadacentral"
)

$gcLibraryUrl = "https://raw.githubusercontent.com/canada-ca/accelerators_accelerateurs-azure/master/Templates/arm"
$serversDevURL = "https://raw.githubusercontent.com/canada-ca-arm/dev/servers/azuredeploy.json"

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************

Select-AzureRmSubscription PwS2-CCC-Validation

# Cleanup old jobs
Get-Job | Remove-Job

# Start the deployment
Write-Host "Starting deployment...";

New-AzureRmDeployment -Location $Location -Name "Deploy-Infrastructure-Dependancies" -TemplateUri "https://raw.githubusercontent.com/canada-ca/accelerators_accelerateurs-azure/master/Templates/arm/masterdeploy/20190319.1/masterdeploysub.json" -TemplateParameterFile (Resolve-Path -Path "$PSScriptRoot\masterdeploysub.parameters.json") -Verbose;

$provisionningState = (Get-AzureRmDeployment -Name "Deploy-Infrastructure-Dependancies").ProvisioningState

if ($provisionningState -eq "Failed") {
    Write-Host "One of the jobs was not successfully created... exiting..."
    exit
}

<#
# Building dependencies needed for the server validation
New-AzureRmDeployment -Location $Location -Name "dependancy-$templateLibraryName-Build-resourcegroups" -TemplateUri "$gcLibraryUrl/resourcegroups/20190207.2/$templateName" -TemplateParameterFile (Resolve-Path "$PSScriptRoot\dependancy-resourcegroups-canadacentral.parameters.json") -Verbose
New-AzureRmResourceGroupDeployment -ResourceGroupName PwS2-validate-servers-1-RG -Name "dependancy-$templateLibraryName-Build-keyvaults" -TemplateUri "$gcLibraryUrl/keyvaults/20190302.1/$templateName" -TemplateParameterFile (Resolve-Path "$PSScriptRoot\dependancy-keyvaults.parameters.json") -_debugLevel "requestContent,responseContent" -Verbose -AsJob
New-AzureRmResourceGroupDeployment -ResourceGroupName PwS2-validate-servers-1-RG -Name "dependancy-$templateLibraryName-Build-vnet-subnet-1" -TemplateUri "$gcLibraryUrl/vnet-subnet/20190302.2/$templateName" -TemplateParameterFile (Resolve-Path "$PSScriptRoot\dependancy-vnet-subnet.parameters.json") -_debugLevel "requestContent,responseContent" -Verbose -AsJob
New-AzureRmResourceGroupDeployment -ResourceGroupName PwS2-validate-servers-1-RG -Name "dependancy-$templateLibraryName-Build-storage-1" -TemplateUri "$gcLibraryUrl/storage/20190302.2/$templateName" -TemplateParameterFile (Resolve-Path "$PSScriptRoot\dependancy-storage.parameters.json") -_debugLevel "requestContent,responseContent" -Verbose -AsJob
New-AzureRmResourceGroupDeployment -ResourceGroupName PwS2-validate-servers-1-RG -Name "dependancy-$templateLibraryName-Build-availabilityset-1" -TemplateUri "$gcLibraryUrl/availabilityset/20190302.2/$templateName" -TemplateParameterFile (Resolve-Path "$PSScriptRoot\dependancy-availabilityset.parameters.json") -_debugLevel "requestContent,responseContent" -Verbose -AsJob

Get-Job | Wait-Job
Get-Job | Receive-Job

if (Get-Job -State Failed) {
    Write-Host "One of the jobs was not successfully created... exiting..."
    exit
}

# Cleanup old jobs before running new deployments
Get-Job | Remove-Job
#>

# Validating server template
New-AzureRmResourceGroupDeployment -ResourceGroupName PwS2-validate-servers-1-RG -Name "validate-$templateLibraryName-Build-$templateLibraryName" -TemplateUri $serversDevURL -TemplateParameterFile (Resolve-Path "$PSScriptRoot\validate-servers.parameters.json") -Verbose

$provisionningState = (Get-AzureRmResourceGroupDeployment -ResourceGroupName PwS2-validate-servers-1-RG -Name "validate-$templateLibraryName-Build-$templateLibraryName").ProvisioningState

if ($provisionningState -eq "Failed") {
    Write-Host  "Test deployment failed..."
}

# Cleanup validation resource content
Write-Host "Cleanup validation resource content...";
New-AzureRmResourceGroupDeployment -ResourceGroupName PwS2-validate-servers-1-RG -Mode Complete -TemplateFile (Resolve-Path "$PSScriptRoot\cleanup.json") -Force -Verbose
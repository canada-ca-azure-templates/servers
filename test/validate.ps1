Param(
    [Parameter(Mandatory = $True)][string]$templateLibraryName = "name of template",
    [Parameter(Mandatory = $True)][string]$templateLibraryVersion = "version of template",
    [string]$templateName = "azuredeploy.json",
    [string]$containerName = "library-dev",
    [string]$prodContainerName = "library",
    [string]$storageRG = "PwS2-Infra-Storage-RG",
    [string]$storageAccountName = "azpwsdeploytpnjitlh3orvq",
    [string]$Location = "canadacentral"
)

function Output-DeploymentName {
    param( [string]$Name)

    $pattern = '[^a-zA-Z0-9-]'

    # Remove illegal characters from deployment name
    $Name = $Name -replace $pattern, ''

    # Truncate deplayment name to 64 characters
    $Name.subString(0, [System.Math]::Min(64, $Name.Length))
}
$devBaseTemplateUrl = "https://$storageAccountName.blob.core.windows.net/$containerName/arm"
$prodBaseTemplateUrl = "https://$storageAccountName.blob.core.windows.net/$prodContainerName/arm"
$gcLibraryUrl = "https://azpwsdeployment.blob.core.windows.net/library/arm"

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************

# Cleanup old jobs
Get-Job | Remove-Job

#Set-AzureRmCurrentStorageAccount -ResourceGroupName $storageRG -Name $storageAccountName
    
#Create the SaS token for the dev contrainer
#$devToken = New-AzureStorageContainerSASToken -Name $containerName -Permission r -ExpiryTime (Get-Date).AddMinutes(30.0)
#$prodToken = New-AzureStorageContainerSASToken -Name $prodContainerName -Permission r -ExpiryTime (Get-Date).AddMinutes(30.0)

# Start the deployment
Write-Host "Starting deployment...";

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

# Validating server template
New-AzureRmResourceGroupDeployment -ResourceGroupName PwS2-validate-servers-1-RG -Name "validate-$templateLibraryName-Build-$templateLibraryName" -TemplateUri "$devBaseTemplateUrl/servers/$templateLibraryVersion/azuredeploy.json" -TemplateParameterFile (Resolve-Path "$PSScriptRoot\validate-servers.parameters.json") -Verbose

$provisionningState = (Get-AzureRmResourceGroupDeployment -ResourceGroupName PwS2-validate-servers-1-RG -Name "validate-$templateLibraryName-Build-$templateLibraryName").ProvisioningState

if ($provisionningState -eq "Failed") {
    Write-Host  "Test deployment failed..."
}

# Cleanup validation resource content
Write-Host "Cleanup validation resource content...";
New-AzureRmResourceGroupDeployment -ResourceGroupName PwS2-validate-servers-1-RG -Mode Complete -TemplateFile (Resolve-Path "$PSScriptRoot\cleanup.json") -Force -Verbose

Get-Job | Wait-Job
Get-Job | Receive-Job
Param(
    [Parameter(Mandatory=$True)][string]$templateLibrarySrc = "deployment template file formatted as templateMame/version",
    [Parameter(Mandatory=$True)][string]$templateLibraryDst = "path to copy files under arm folder",
    [string]$storageRG = "AzPwS01-Infra-Storage-RG",
    [string]$storageAccountName = "azpwsdeployment",
    [string]$containerName = "library-dev",
    [string]$subscriptionId = "2de839a0-37f9-4163-a32a-e1bdb8d6eb7e"
)

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"

# sign in
#Write-Host "Logging in...";
if ([string]::IsNullOrEmpty($(Get-AzureRmContext).Account)) {
    Write-Host "You need to login. Minimize the Visual Studio Code and login to the window that poped-up"
    Login-AzureRmAccount
}

Select-AzureRmSubscription -SubscriptionID $subscriptionId
$destKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $storageRG -AccountName $storageAccountName).Value[0]

###############################################################################################################################################
# WARNING! The use of this script can lead to serious unintended consequence if the wrong src and dst folders are used. You have been warned! #
###############################################################################################################################################
#
# Example use of script: .\scripts\manual-copy.ps1 -templateLibrarySrc ..\arm\servers\20181025 -templateLibraryDst servers/20181025
# or
#                        .\scripts\manual-copy.ps1 ..\arm\servers\20181025 servers/20181025
#

$templateBlobDest = "https://$storageAccountName.blob.core.windows.net/library-dev/arm/$templateLibraryDst/"
$destKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $storageRG -AccountName $storageAccountName).Value[0]

# Important step to expand the received path to the library to a fully qualified path
$templateLibrarySrc = Resolve-Path $templateLibrarySrc

Write-Host "Copying folder $templateLibrarySrc to $templateBlobDest"

AzCopy /Source:$templateLibrarySrc /Dest:$templateBlobDest /DestKey:$destKey /S /Y
Manual execution of validation does like this:

select-azurermsubscription PwS2-CCC-Validation

..\..\..\Core\deployments\scripts\manual-copy.ps1 -templateLibrarySrc ..\template\ -templateLibraryDst nsg/bernard-dev -storageRG PwS2-Infra-Storage-RG -storageAccountName azpwsdeploytpnjitlh3orvq -containerName library-dev

.\manual-copy.ps1 -templateLibrarySrc ..\template\ -templateLibraryDst servers/bernard-dev -storageRG PwS2-Infra-Storage-RG -storageAccountName azpwsdeploytpnjitlh3orvq -containerName library-dev

then

.\validate-manual.ps1 -templateLibraryName servers -templateLibraryVersion bernard-dev

#Test 4 seems to hang for 30-40mins+
 {
                    "comment": "Test Linux vm using a keyvault with [unique] in name and disk encryption",
                    "resourceGroup": "PwS2-validate-servers-1-RG",
                    "vmKeyVault": {
                        "keyVaultResourceGroupName": "PwS2-validate-servers-1-RG",
                        "keyVaultName": "PwS2-validate-[unique]"
                    },
                    "vm": {
                        "computerName": "test4",
                        "adminUsername": "azureadmin",
                        "adminPassword": "linuxDefaultPassword",
                        "vmSize": "Standard_B1s",
                        "bootDiagnostic": true,
                        "storageProfile": {
                            "osDisk": {
                                "createOption": "fromImage",
                                "managedDisk": {
                                    "storageAccountType": "StandardSSD_LRS"
                                }
                            },
                            "dataDisks": [],
                            "imageReference": {
                                "publisher": "RedHat",
                                "offer": "RHEL",
                                "sku": "7-RAW",
                                "version": "latest"
                            }
                        }
                    },
                    "networkSecurityGroups": {
                        "name": "nsg",
                        "properties": {
                            "securityRules": []
                        }
                    },
                    "networkInterfaces": {
                        "name": "NIC1",
                        "acceleratedNetworking": false,
                        "vnetResourceGroupName": "PwS2-validate-servers-1-RG",
                        "vnetName": "PwS2-validate-servers-1-VNET",
                        "subnetName": "test1"
                    },
                    "tagValues": {
                        "Owner": "build.pipeline@tpsgc-pwgsc.gc.ca",
                        "CostCenter": "PSPC-EA",
                        "Enviroment": "Validate",
                        "Classification": "Unclassified",
                        "Organizations": "PSPC-CCC-E&O",
                        "DeploymentVersion": "2019-01-11-01"
                    }
                },
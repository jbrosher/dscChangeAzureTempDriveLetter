# dscChangeAzureTempDriveLetter

PowerShell DSC Configuration Package to change the Temp Drive letter for Azure VMs to the T Drive and relocate the Page File to the new T Drive letter.

The DSC Configuration performs the following steps:

1) Checks Win32_Volume for a D: Drive Letter with a label of Temporary Storage
2) If step 1 is TRUE then it will delete the Page File configuration and restarts the VM
3) Changes Win32_Volume using the D: Drive Letter with a label of Temporary Storage to use the T drive letter
4) Sets the Page File configuration to use the T drive letter and restarts the VM

## Package Zip File for use in the PowerShell DSC Extension

> Note: Azure PowerShell DSC VM extension requires files to be packaged in a specific way and requires AZ Powershell Modules to be installed to create the Archive

1) Publish Zip FIle Directly to a Storage Account

    ``` PowerShell
    $storageAccountName = "<storage_account_name>"
    $storageResourceGroupName = "<storage_resource_group_name>"
    $pathToConfigurationScript = "<path_to_script>"

    Publish-AzVMDscConfiguration -ResourceGroupName $storageResourceGroupName -StorageAccountName $storageAccountNam -ConfigurationPath $pathToConfigurationScript -Force
    ```

2) Publish Zip File To Local Directory to be uploaded manually

    ``` PowerShell
    $pathToConfigurationScript = "<path_to_script>"
    $pathToSaveZip = "<path_to_save_zip>"

    Publish-AzVMDscConfiguration -ConfigurationPath $pathToConfigurationScript -OutputArchivePath "$($pathToSaveZip)\dscChangeAzureTempDriveLetter.ps1.zip" -Force
    ```

## How to Deploy Using ARM Template

1) If you have an existing DSC extension you will have to remove it before deploying this.
2) Upload Zip file to a storage account
3) Modify the azuredeploy.parameters.json file with your vmName and zipURI

    ``` JSON
    {
        "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
        "contentVersion": "1.0.0.0",
        "parameters": {
            "vmName": {
                "value": "<vm_name>"
            },
            "sasURI": {
                "value": "<zip_uri>"
            }
        }
    }
    ```

4) Deploy the ARM template to the Resource Group that contains your VM

## How to Deploy Using PowerShell

> Note: Requires AZ Powershell Modules to be installed and assumes the 'dscChangeAzureTempDriveLetter.ps1.zip' file exists in the 'windows-powershell-dsc' container

1) If you have an existing DSC extension you will have to remove it before deploying this.
2) Upload Zip file to a storage account
3) Update the following PowerShell Script with your vmName, vmResourceGroupName, storageAccountName

    ``` PowerShell
    $vmName = "<vm_name>"
    $vmResourceGroupName = "<resource_group_name_containing_vm>"
    $storageAccountName = "<storage_account_name>"

    Set-AzVMDscExtension `
        -Version '2.77' `
        -ResourceGroupName $vmResourceGroupName `
        -VMName $vmName `
        -ArchiveStorageAccountName $storageAccountName `
        -ArchiveBlobName 'dscChangeAzureTempDriveLetter.ps1.zip' `
        -ConfigurationName 'dscChangeAzureTempDriveLetter' `
        -AutoUpdate
    ```

4) Execute the PowerShell Script

## How to Deploy Using Terraform

1) If you have an existing DSC extension you will have to remove it before deploying this.
2) Upload Zip file to a storage account
3) Update the locals in vmDSCExtension.tf file with your vmName, vmID, and zipURI

    ``` Terraform
    locals {
        vmName = "<vm_name>" 
        vmID   = "<vm_resource_id>"
        zipURI = "<zip_uri>"
    }
    ```

4) Use Terraform to deploy the vmDSCExtension.tf file

## How it works

1) The PowerShell DSC Configuration checks for a Page File configuration using the D Drive Letter

    ``` PowerShell
    $pageFile = Get-WmiObject -Class Win32_PageFileSetting
    if ($pageFile -eq $null) { return $true }
    if ($pageFile.Name.ToLower().Contains('d:')) { return $false }
    else { return $true }
    ```

2) The PowerShell DSC Configuration will delete the Page File configuration if it is using the D Drive Letter

    ``` PowerShell
    $pageFile = Get-WmiObject -Class Win32_PageFileSetting
    $pageFile
    $pageFile.Delete()
    Restart-Computer -Force
    ```

3) The PowerShell DSC Configuration will check to ensure the Page File Configuration is cleared

    ``` PowerShell
    $pageFile = Get-WmiObject -Class Win32_PageFileSetting
    if ($pageFile -eq $null) { return $false }
    else { return $true }
    ```

4) The PowerShell DSC Configuration will then use WMI to change the drive letter, enable the Page File on the new T drive letter, and reboot

    ``` PowerShell
    Get-Partition -DriveLetter "D"| Set-Partition -NewDriveLetter "T"
    Set-WMIInstance -Class Win32_PageFileSetting -Arguments @{ Name = "T:\pagefile.sys"; MaximumSize = 0; }
    Restart-Computer -Force
    ```

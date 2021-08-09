locals {
    vmName = "<vm_name>" 
    vmID   = "<vm_resource_id>"
    zipURI = "<zip_uri>"
}

resource "azurerm_virtual_machine_extension" "dscChangeAzureTempDriveLetter" {
  name                       = "${local.vmName}/dscChangeAzureTempDriveLetter"
  virtual_machine_id         = local.vmID
  publisher                  = "Microsoft.PowerShell"
  type                       = "DSC"
  type_handler_version       = "2.77"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
        "modulesURL": "${local.zipURI}"
        "wmfVersion": "latest"
        "configurationFunction": "dscChangeAzureTempDriveLetter.ps1\\dscChangeAzureTempDriveLetter"
    }
SETTINGS
}
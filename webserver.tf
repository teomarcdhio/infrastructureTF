## You'll need public IPs for each VM for Ansible to connect to and to deploy the web app to.
resource "azurerm_public_ip" "webserverIps" {
  count                   = 2
  name                    = "publicWebserverIp-${count.index}"
  location                = azurerm_resource_group.testRG.location
  resource_group_name     = azurerm_resource_group.testRG.name
  allocation_method       = "Dynamic"
  domain_name_label       = "${var.domain_name_prefix}-w-${count.index}"
}

## Create a vNic for each VM. 
resource "azurerm_network_interface" "winNI" {
  count               = 2
  name                = "webserver-nic-${count.index}"
  location            = azurerm_resource_group.testRG.location
  resource_group_name = azurerm_resource_group.testRG.name
  
  ## Ip configuration for each vNic
  ip_configuration {
    name                          = "ip_config"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.webserverIps[count.index].id
  }
  
  ## Ensure the subnet is created first before creating these vNics.
  depends_on = [
    azurerm_subnet.internal
  ]
}

## Create the Windows VMs and link the vNIcs created earlier
resource "azurerm_windows_virtual_machine" "webserverVMs" {
  count                 = 2
  name                  = "webservervm-${count.index}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.testRG.name
  size                  = "Standard_DS1_v2"
  network_interface_ids = [azurerm_network_interface.winNI[count.index].id]
  computer_name         = "webservervm-${count.index}"
  admin_username        = var.winvmuser
  admin_password        = var.winvmpass
  
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  depends_on = [
    azurerm_network_interface.winNI
  ]
}

## Download and run the powershell script to allow Ansiblke via WinRM. 
## exit code has to be 0
resource "azurerm_virtual_machine_extension" "enablewinrm" {
  count                 = 2
  name                  = "enablewinrm"
  virtual_machine_id    = azurerm_windows_virtual_machine.webserverVMs[count.index].id
  publisher            = "Microsoft.Compute" ## az vm extension image list --location eastus Do not use Microsoft.Azure.Extensions here
  type                 = "CustomScriptExtension" ## az vm extension image list --location eastus Only use CustomScriptExtension here
  type_handler_version = "1.9" ## az vm extension image list --location eastus
  auto_upgrade_minor_version = true
  settings = <<SETTINGS
    {
      "fileUris": ["https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"],
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File ConfigureRemotingForAnsible.ps1"
    }
SETTINGS
}

output "webserverIps" {
  value       = azurerm_public_ip.webserverIps.*.ip_address
}


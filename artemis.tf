## You'll need public IPs for each VM for Ansible to connect to and to deploy the web app to.
resource "azurerm_public_ip" "artemisIps" {
  count                   = 1
  name                    = "publicartemisIp-${count.index}"
  location                = azurerm_resource_group.testRG.location
  resource_group_name     = azurerm_resource_group.testRG.name
  allocation_method       = "Dynamic"
  domain_name_label       = "${var.domain_name_prefix}-a-${count.index}"
}

## Create a vNic for each VM. 
resource "azurerm_network_interface" "linuxNI" {
  count               = 1
  name                = "artemis-nic-${count.index}"
  location            = azurerm_resource_group.testRG.location
  resource_group_name = azurerm_resource_group.testRG.name
  
  ## Ip configuration for each vNic
  ip_configuration {
    name                          = "ip_config"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.artemisIps[count.index].id
  }
  
  ## Ensure the subnet is created first before creating these vNics.
  depends_on = [
    azurerm_subnet.internal
  ]
}

# Create (and display) an SSH key
resource "tls_private_key" "test_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tls_private_key" { 
    value = tls_private_key.test_ssh.private_key_pem 
    sensitive = true
}

## Create the Linux VMs and link the vNIcs created earlier
resource "azurerm_linux_virtual_machine" "artemisVMs" {
  count                 = 1
  name                  = "artemisvm-${count.index}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.testRG.name
  size                  = "Standard_DS1_v2"
  network_interface_ids = [azurerm_network_interface.linuxNI[count.index].id]
  computer_name         = "artemisvm-${count.index}"
  admin_username        = var.linuxuser
  
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = var.linuxuser
    public_key = tls_private_key.test_ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  depends_on = [
    azurerm_network_interface.linuxNI
  ]
}

output "artemisIps" {
  value       = azurerm_public_ip.artemisIps.*.ip_address
}


# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }
  backend "remote" {
    organization = "MatteoOrg"

    workspaces {
      name = "TestInfr"
    }
  }

  required_version = ">= 0.14.9"
}
## Ensure you're using 2.0+ of the azurevm provider to get the azurerm_windows_virtual_machine reosurce and
## the other resources and capabilities
provider "azurerm" {
  features {}
}

## Create an Azure resource group using the value of resource_group and the location of the location variable
## defined in the terraform.auto.tfvars file.
resource "azurerm_resource_group" "testRG" {
  name     = var.resource_group
  location = var.location
}


## Create an Azure network security group.
resource "azurerm_network_security_group" "testSG" {
  name                = "nsg"
  location            = azurerm_resource_group.testRG.location
  resource_group_name = azurerm_resource_group.testRG.name
}
## Allow Ansible to connect to each VM from management ip
resource "azurerm_network_security_rule" "allowWinRm" {
  name                       = "allowWinRm"
  priority                   = 101
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "5986"
  source_address_prefix      = var.management_ip
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.testRG.name
  network_security_group_name = azurerm_network_security_group.testSG.name
}
  
 
## Create a rule to allow to connect to the web app
resource "azurerm_network_security_rule" "allowPublicWeb" {
  name                       = "allowPublicWeb"
  priority                   = 103
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "80"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.testRG.name
  network_security_group_name = azurerm_network_security_group.testSG.name
}
  
## Allow RDP to the VMs to troubleshoot
 resource "azurerm_network_security_rule" "allowRDP" {
  name                       = "allowRDP"
  priority                   = 104
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "3389"
  source_address_prefix      = var.management_ip
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.testRG.name
  network_security_group_name = azurerm_network_security_group.testSG.name
}

## Allow SSH to connect to each VM from management ip
resource "azurerm_network_security_rule" "allowSSH" {
  name                       = "allowSSH"
  priority                   = 105
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = var.management_ip
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.testRG.name
  network_security_group_name = azurerm_network_security_group.testSG.name
}

## Link the NSG to each of the VMs' NICs
#resource "azurerm_network_interface_security_group_association" "nsg" {
#  count                     = 3
#  network_interface_id      = azurerm_network_interface.*[count.index].id
#  network_security_group_id = azurerm_network_security_group.testSG.id
#}

## Create a simple vNet
resource "azurerm_virtual_network" "main" {
  name                = "test-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.testRG.location
  resource_group_name = azurerm_resource_group.testRG.name
}

## Create a simple subnet inside of th vNet ensuring the VMs are created first (depends_on)
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.testRG.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

  depends_on = [
    azurerm_virtual_network.main
  ]
}



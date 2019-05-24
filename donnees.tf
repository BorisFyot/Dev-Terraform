# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "donnes" {
    name     = "Devs"
    location = "eastus"

    tags {
        environment = "data"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "donnes" {
    name                = "donnes_Net_SecurityGroup"
    location            = "${azurerm_resource_group.donnes.location}"
    resource_group_name = "${azurerm_resource_group.donnes.name}"
    
    security_rule {
        name                       = "donnes_Outrule"
        priority                   = 101
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "445"
        destination_port_range     = "445"
        source_address_prefix      = "10.2.1.0/29"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "donnes_Inrule2"
        priority                   = 102
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "1251"
        destination_port_range     = "1251"
        source_address_prefix      = "10.1.0.0/16"
        destination_address_prefix = "10.2.0.0/16"
    }

    security_rule {
        name                       = "donnes_Outrule2"
        priority                   = 103
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "1251"
        destination_port_range     = "1251"
        source_address_prefix      = "10.2.0.0/16"
        destination_address_prefix = "10.1.0.0/16"
    }

    tags {
        environment = "data"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "donnes" {
    name                = "donnes_myVnet"
    address_space       = ["10.2.0.0/16"]
    location            = "${azurerm_resource_group.donnes.location}"
    resource_group_name = "${azurerm_resource_group.donnes.name}"

    tags {
        environment = "data"
    }
}

# Create subnet1
resource "azurerm_subnet" "donnes" {
    name                 = "donnes_Subnet1"
    resource_group_name  = "${azurerm_resource_group.donnes.name}"
    virtual_network_name = "${azurerm_virtual_network.donnes.name}"
    address_prefix       = "10.2.1.0/29"
    network_security_group_id = "${azurerm_network_security_group.donnes.id}"
}

# Create public IPs
resource "azurerm_public_ip" "donnes" {
    count                        = 1
    name                         = "donnes_myPublicIP-${count.index}"
    location                     = "${azurerm_resource_group.donnes.location}"
    resource_group_name          = "${azurerm_resource_group.donnes.name}"
    allocation_method            = "Dynamic"

    tags {
        environment = "data"
    }
}

# Create network interface
resource "azurerm_network_interface" "donnes" {
    count                     = 1
    name                      = "donnes_myNIC-${count.index}"
    location                  = "${azurerm_resource_group.donnes.location}"
    resource_group_name       = "${azurerm_resource_group.donnes.name}"

    ip_configuration {
        name                          = "donnes_Configuration"
        subnet_id                     = "${azurerm_subnet.donnes.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${element(azurerm_public_ip.donnes.*.id, count.index)}"
    }

    tags {
        environment = "data"
    }
}



# Create virtual machine 1
resource "azurerm_virtual_machine" "donnes" {
    count                 = 1
    name                  = "donnes-${count.index}"
    location              = "${azurerm_resource_group.donnes.location}"
    resource_group_name   = "${azurerm_resource_group.donnes.name}"
    network_interface_ids = ["${element(azurerm_network_interface.donnes.*.id, count.index)}"]
    vm_size               = "Standard_B1ms"

    storage_os_disk {
        name              = "donnes-OsDisk-${count.index}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  ="donnes-${count.index}"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC25G/wnpjYHounebrOuLmEjrb3FSpXCTUDATuBXfISLeg4LYUdl6Xdf5gEpnC4tu1vrWJ8Kx8OtJbcErKcaN6fa8x0M8O5C3xyuaAcnjc4wZsJExXZTLE7cuJrdVmtdrn6slA+bYzyecFb35h8S6gO1uyNGNgjbkwdPU/khKzqwHd2gbxg56NNQFMFGwlLV2Lp9BubGD+ksMwUS9G81c0F6qEgdJ3bPfOql03qEwA+HeMdBWlXaA2lPpiV9i6MgbVNGLA6qeUL1sMp3jA5FdRq9SOxVO9fncz9Pbm04k8li0AtN7w/4lYtC0SzL8Y+5zirc32+ovCe9eFWde7Vz0M5 adminl@localhost.localdomain"
        }
    }

    tags {
        environment = "data"
    }
}
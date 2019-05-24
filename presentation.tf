# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "presentation" {
    name     = "LB"
    location = "eastus"

    tags {
        environment = "Tech"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "presentation" {
    name                = "Presentation_myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "${azurerm_resource_group.presentation.location}"
    resource_group_name = "${azurerm_resource_group.presentation.name}"

    tags {
        environment = "Tech"
    }
}

# Create subnet1
resource "azurerm_subnet" "presentation" {
    name                 = "Presentation_Subnet1"
    resource_group_name  = "${azurerm_resource_group.presentation.name}"
    virtual_network_name = "${azurerm_virtual_network.presentation.name}"
    address_prefix       = "10.0.1.0/29"
}


# Create public IPs
resource "azurerm_public_ip" "presentation" {
    name                         = "Presentation_myPublicIP"
    location                     = "${azurerm_resource_group.presentation.location}"
    resource_group_name          = "${azurerm_resource_group.presentation.name}"
    allocation_method            = "Dynamic"

    tags {
        environment = "Tech"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "presentation" {
    name                = "Presentation_Net_SecurityGroup"
    location            = "${azurerm_resource_group.presentation.location}"
    resource_group_name = "${azurerm_resource_group.presentation.name}"
    
    security_rule {
        name                       = "SSH"
        priority                   = 101
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "7050_Outrule"
        priority                   = 102
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "7050"
        destination_port_range     = "7050"
        source_address_prefix      = "*"
        destination_address_prefix = "10.1.0.0/16"
    }


    security_rule {
        name                       = "7050_Inrule"
        priority                   = 103
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "7050"
        destination_port_range     = "7050"
        source_address_prefix      = "10.1.0.0/16"
        destination_address_prefix = "10.0.0.0/16"
    }

    security_rule {
        name                       = "Presentation_Inrule"
        priority                   = 104
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "80"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }


    tags {
        environment = "Tech"
    }
}



resource "azurerm_lb" "presentation" {
    name                = "loadBalancer"
    location            = "${azurerm_resource_group.presentation.location}"
    resource_group_name = "${azurerm_resource_group.presentation.name}"

    frontend_ip_configuration {
        name                 = "publicIPAddress"
        public_ip_address_id = "${azurerm_public_ip.presentation.id}"
    }
}

resource "azurerm_lb_backend_address_pool" "presentation" {
    resource_group_name = "${azurerm_resource_group.presentation.name}"
    loadbalancer_id     = "${azurerm_lb.presentation.id}"
    name                = "BackEndAddressPool"
}

# Create network interface
resource "azurerm_network_interface" "presentation" {
    count                     = 2
    name                      = "myNIC-${count.index}"
    location                  = "${azurerm_resource_group.presentation.location}"
    resource_group_name       = "${azurerm_resource_group.presentation.name}"
    network_security_group_id = "${azurerm_network_security_group.presentation.id}"

    ip_configuration {
        name                          = "presentation-NicConfiguration"
        subnet_id                     = "${azurerm_subnet.presentation.id}"
        private_ip_address_allocation = "Dynamic"
//        load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.presentation.id}"]
    }

    tags {
        environment = "Tech"
    }
}

resource "azurerm_network_interface_backend_address_pool_association" "presentation" {
  count                   = 2
  network_interface_id    = "${element(azurerm_network_interface.presentation.*.id, count.index)}"
  ip_configuration_name   = "presentation-NicConfiguration"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.presentation.id}"
}

resource "azurerm_availability_set" "presentation" {
 name                         = "avset"
 location                     = "${azurerm_resource_group.presentation.location}"
 resource_group_name          = "${azurerm_resource_group.presentation.name}"
 platform_fault_domain_count  = 2
 platform_update_domain_count = 2
 managed                      = true
}

# Create virtual machine 1
resource "azurerm_virtual_machine" "presentation" {
    count                 = 2
    name                  = "presentation-${count.index}"
    location              = "${azurerm_resource_group.presentation.location}"
    availability_set_id   = "${azurerm_availability_set.presentation.id}"
    resource_group_name   = "${azurerm_resource_group.presentation.name}"
    network_interface_ids = ["${element(azurerm_network_interface.presentation.*.id, count.index)}"]
    vm_size               = "Standard_B1ms"

    storage_os_disk {
        name              = "presentation-OsDisk-${count.index}"
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
        computer_name  ="presentation-${count.index}"
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
        environment = "Tech"
    }
}
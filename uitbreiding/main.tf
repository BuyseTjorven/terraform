resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  name     = random_pet.rg_name.id
  location = var.resource_group_location
}

resource "random_pet" "azurerm_virtual_network_name" {
  prefix = "vnet"
}

resource "azurerm_virtual_network" "test" {
  name                = random_pet.azurerm_virtual_network_name.id
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "random_pet" "azurerm_subnet_name" {
  prefix = "sub"
}

resource "azurerm_subnet" "test" {
  name                 = random_pet.azurerm_subnet_name.id
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "test" {
  name                = "publicIPForLB"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "test" {
  name                = "loadBalancer"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  frontend_ip_configuration {
    name                 = "publicIPAddress"
    public_ip_address_id = azurerm_public_ip.test.id
  }
}

resource "azurerm_lb_backend_address_pool" "test" {
  loadbalancer_id = azurerm_lb.test.id
  name            = "BackEndAddressPool"
}

resource "azurerm_network_interface_backend_address_pool_association""test"{
    count = 2
    network_interface_id = azurerm_network_interface.test[count.index].id
    ip_configuration_name = azurerm_network_interface.test[count.index].ip_configuration[0].name
    backend_address_pool_id = azurerm_lb_backend_address_pool.test.id

}
########## hier zo de vm's in zo een pool ding steken snapje.
####https://github.com/Azure/terraform-azurerm-loadbalancer/blob/main/main.tf


resource "azurerm_network_interface" "test" {
  count               = 2
  name                = "acctni${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "testConfiguration"
    subnet_id                     = azurerm_subnet.test.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_availability_set" "avset" {
  name                         = "avset"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

resource "random_pet" "azurerm_linux_virtual_machine_name" {
  prefix = "vm"
}

resource "azurerm_ssh_public_key" "sshkey" {
  name                = var.ssh_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.resource_group_location
  public_key          = file(var.public_ssh_key)
}

resource "azurerm_lb_nat_rule" "test" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.test.id
  name                           = "ssh"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = azurerm_lb.test.frontend_ip_configuration[0].name
}

resource "azurerm_network_interface_nat_rule_association" "test" {
  network_interface_id  = azurerm_network_interface.test[0].id
  ip_configuration_name = azurerm_network_interface.test[0].ip_configuration[0].name
  nat_rule_id           = azurerm_lb_nat_rule.test.id
}

resource "azurerm_lb_nat_rule" "test1" {
  resource_group_name            = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.test.id
  name                           = "ssh1"
  protocol                       = "Tcp"
  frontend_port                  = 2222
  backend_port                   = 22
  frontend_ip_configuration_name = azurerm_lb.test.frontend_ip_configuration[0].name
}

resource "azurerm_network_interface_nat_rule_association" "test1" {
  network_interface_id  = azurerm_network_interface.test[1].id
  ip_configuration_name = azurerm_network_interface.test[1].ip_configuration[0].name
  nat_rule_id           = azurerm_lb_nat_rule.test1.id
}

resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.test.id
  frontend_ip_configuration_name = azurerm_lb.test.frontend_ip_configuration[0].name
  name                           = "Terrarule"
  frontend_port                  = 80
  backend_port                   = 80
  protocol                       = "Tcp"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.test.id]
  probe_id                       = azurerm_lb_probe.test.id
  disable_outbound_snat          = true
}

resource "azurerm_lb_probe" "test" {
  loadbalancer_id = azurerm_lb.test.id
  name            = "ssh-running-probe"
  port            = 22
}

# resource "azurerm_lb_nat_rule" "test" {
#     for_each = var.nat_rules
#     resource_group_name            = azurerm_resource_group.rg.name
#     loadbalancer_id                = azurerm_lb.test.id
#     name                           = each.value.name
#     protocol                       = each.value.protocol
#     frontend_port                  = each.value.frontend_port
#     backend_port                   = each.value.backend_port
#     frontend_ip_configuration_name = azurerm_lb.test.frontend_ip_configuration[0].name
# }


resource "azurerm_linux_virtual_machine" "test" {
  count                 = 2
  name                  = "${random_pet.azurerm_linux_virtual_machine_name.id}${count.index}"
  location              = azurerm_resource_group.rg.location
  availability_set_id   = azurerm_availability_set.avset.id
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.test[count.index].id]
  size                  = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl start nginx",
      "echo '<h1>Hello World from ${count.index}</h1>' | sudo tee -a /var/www/html/index.html"
    ]
    
  }
  connection {
    type        = "ssh"
    host        = azurerm_public_ip.test.ip_address
    user        = var.username
    private_key = file(var.private_ssh_key)
    port = count.index == 0 ? 22 : 2222
  }

  admin_ssh_key {
    username   = var.username
    public_key = azurerm_ssh_public_key.sshkey.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "myosdisk${count.index}"
  }

  computer_name  = "hostname"
  admin_username = var.username
}

resource "azurerm_managed_disk" "test" {
  count                = 2
  name                 = "datadisk_existing_${count.index}"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1024"
}

resource "azurerm_virtual_machine_data_disk_attachment" "test" {
  count              = 2
  managed_disk_id    = azurerm_managed_disk.test[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.test[count.index].id
  lun                = "10"
  caching            = "ReadWrite"
}

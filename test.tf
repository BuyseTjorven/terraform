provider "vsphere" {
  user                 = "administrator@vsphere.local"
  password             = "P@ssw0rd"
  vsphere_server       = "192.168.50.10"
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "datacenter" {
  name = "StudentDC"
}

data "vsphere_datastore" "datastore" {
  name          = "buyse-tjorven"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = "Lab"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "template" {
  name          = "Ubuntu_template"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}
resource "vsphere_folder" "folder" {
  path          = "terraform"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_virtual_machine" "vm" {
  name             = "hello-world"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = data.vsphere_virtual_machine.template.num_cpus
  memory           = data.vsphere_virtual_machine.template.memory
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  scsi_type        = data.vsphere_virtual_machine.template.scsi_type
  firmware         = data.vsphere_virtual_machine.template.firmware
  folder           = vsphere_folder.folder.path
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }
  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {
      linux_options {
        host_name = "hello-world"
        domain    = "example.com"
      }
      network_interface {
        ipv4_address = "192.168.50.60"
        ipv4_netmask = 24
      }
      ipv4_gateway = "192.168.50.1"
    }
  }
  provisioner "remote-exec" {
    inline = [
      "sudo -i",
      "tjorven",
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx",
    ]
    connection {
      host     = self.clone[0].customize[0].network_interface[0].ipv4_address
      type     = "ssh"
      user     = var.ubuntu_username
      password = var.ubuntu_password
      timeout  = "2m"
    }

  }
}

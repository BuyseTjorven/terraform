variable "resource_group_location" {
  type        = string
  description = "Location for all resources."
  default     = "eastus"
}

variable "resource_group_name_prefix" {
  type        = string
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
  default     = "rg"
}

variable "username" {
  type        = string
  description = "The username for the local account that will be created on the new VM."
  default     = "azureadmin"
}

variable "public_ssh_key" {
  type        = string
  description = "Path to the public SSH key file."
  default     = "C:/Users/tjorven/Documents/terraform/uitbreiding/keys/terraform.pub"


  #path nog fixen
}
variable "private_ssh_key" {
  type        = string
  description = "Path to the private SSH key file."
  default     = "C:/Users/tjorven/Documents/terraform/uitbreiding/keys/terraform.pem"
  
}

variable "ssh_name" {
  type        = string
  description = "Name of the SSH key resource."
  default     = "sshkey"
}

variable "nat_rules" {
  type = map(any)
  description = "Map of NAT rules to create."
  default = {
    ssh = {
      name          = "ssh"
      protocol      = "Tcp"
      frontend_port = 22
      backend_port  = 22
    },
    ssh2 = {
      name          = "ssh2"
      protocol      = "Tcp"
      frontend_port = 2222
      backend_port  = 22
    }
  }
  
}
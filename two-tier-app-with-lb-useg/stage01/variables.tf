variable "username" {
    type = string
}
variable "password" { 
    sensitive   = true
    type = string 
}

variable "deployment_name" {
    type = string
}
variable "vcenter" {
    type = string
}
variable "vsphere_datacenter" {
    type = string
}
variable "vsphere_cluster" {
    type = string
}
variable "vsphere_datastore" {
    type = string
}

variable "app_storage_policy" {
    type = string
}

variable "db_storage_policy" {
    type = string
}

variable "app_vms" {
    type = list
}
variable "app_cpus" {
    type = number
}
variable "app_memory" {
    type = number
}
variable "app_disk" {
    type = number
}

variable "db_vms" {
    type = list
}
variable "db_cpus" {
    type = number
}
variable "db_memory" {
    type = number
}

variable "db_disk" {
    type = number
}

variable "dns_suffix_list" {
   type = list(string)
}
variable "dns_server_list" {
    type = list(string)
}
variable "domain" {
    type = string
}
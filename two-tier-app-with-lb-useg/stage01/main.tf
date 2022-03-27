terraform {
  required_providers {
    vsphere = {
      source = "hashicorp/vsphere"
      version = "2.0.2"
    }
  }
}

# configure basic vSphere provider settings
provider "vsphere" {
  vsphere_server = var.vcenter
  user = var.username
  password = var.password
  allow_unverified_ssl  = true
}

# fetch the DataCenter object that will be used during deployment
data "vsphere_datacenter" "datacenter" {
  name = var.vsphere_datacenter
}

# fetch the Cluster object that will be used during deployment
data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# fetch the datastore object that will be used during deployment
data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# fetch the policy object for app, this avoids using "vSAN Default Storage Policy"
data "vsphere_storage_policy" "app_storage_policy" {
  name = var.app_storage_policy
}

# fetch the policy object for db, this avoids using "vSAN Default Storage Policy"
data "vsphere_storage_policy" "db_storage_policy" {
  name = var.db_storage_policy
}

# fetch the content library that holds all the images
data "vsphere_content_library" "library" {
  name = "sfo-w01-lib01"
}

# fetch the specific OVF that we want to deploy (built with hashicorp packer)
data "vsphere_content_library_item" "item" {
  name       = "linux-ubuntu-20.04lts-v22.03"
  type       = "ovf"
  library_id = data.vsphere_content_library.library.id
}

# fetch the Network object that the VMs will be connected to
data "vsphere_network" "network" {
  name          = "sfo-w01-cl01-demo-pg"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# create a unique folder for this deployment
resource "vsphere_folder" "folder" {
  path          = var.deployment_name
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# create one of multiple virtual machines from the OVF template in the content library
resource "vsphere_virtual_machine" "app" {
  count                   = "${length(var.app_vms)}"
  name                    = format("%s-%s", var.deployment_name, "${lookup(var.app_vms[count.index], "hostname")}" )
  folder                  = var.deployment_name
  datastore_id            = data.vsphere_datastore.datastore.id
  resource_pool_id        = data.vsphere_compute_cluster.cluster.resource_pool_id
  firmware                = "efi"
  num_cpus                = var.app_cpus
  memory                  = var.app_memory
  storage_policy_id       = data.vsphere_storage_policy.app_storage_policy.id

  depends_on = [
    vsphere_folder.folder
  ]

  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label            = "disk0"
    size             = var.app_disk
    thin_provisioned = true
    storage_policy_id = data.vsphere_storage_policy.app_storage_policy.id
  }

  clone {
    template_uuid = data.vsphere_content_library_item.item.id
    customize {
      linux_options {
        host_name = "${lookup(var.app_vms[count.index], "hostname")}"
        domain    = var.domain
      }
      network_interface {
        ipv4_address = "${lookup(var.app_vms[count.index], "ipv4_address")}"
        ipv4_netmask = "${lookup(var.app_vms[count.index], "ipv4_netmask")}"
      }

      ipv4_gateway    = "${lookup(var.app_vms[count.index], "ipv4_gateway")}"
      dns_suffix_list = var.dns_suffix_list
      dns_server_list = var.dns_server_list
    }
  }
}

# create one of multiple virtual machines from the OVF template in the content library
resource "vsphere_virtual_machine" "db" {
  count                   = "${length(var.db_vms)}"
  name                    = format("%s-%s", var.deployment_name, "${lookup(var.db_vms[count.index], "hostname")}" )
  folder                  = var.deployment_name
  datastore_id            = data.vsphere_datastore.datastore.id
  resource_pool_id        = data.vsphere_compute_cluster.cluster.resource_pool_id
  firmware                = "efi"
  num_cpus                = var.db_cpus
  memory                  = var.db_memory
  storage_policy_id       = data.vsphere_storage_policy.db_storage_policy.id

  depends_on = [
    vsphere_folder.folder
  ]

  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label            = "disk0"
    size             = var.db_disk
    thin_provisioned = true
    storage_policy_id= data.vsphere_storage_policy.db_storage_policy.id
  }

  clone {
    template_uuid = data.vsphere_content_library_item.item.id
    customize {
      linux_options {
        host_name = "${lookup(var.db_vms[count.index], "hostname")}"
        domain    = var.domain
      }
      network_interface {
        ipv4_address = "${lookup(var.db_vms[count.index], "ipv4_address")}"
        ipv4_netmask = "${lookup(var.db_vms[count.index], "ipv4_netmask")}"
      }

      ipv4_gateway    = "${lookup(var.db_vms[count.index], "ipv4_gateway")}"
      dns_suffix_list = var.dns_suffix_list
      dns_server_list = var.dns_server_list
    }
  }
}
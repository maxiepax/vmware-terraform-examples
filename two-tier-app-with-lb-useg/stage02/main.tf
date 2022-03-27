terraform {
  required_providers {
    vsphere = {
      source = "hashicorp/vsphere"
      version = "2.0.2"
    }
    nsxt = {                                                                                  ### Addition from stage01 ###
      source = "vmware/nsxt"
      version = "3.2.5"
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
    storage_policy_id       = data.vsphere_storage_policy.app_storage_policy.id
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

  connection {
    type     = "ssh"
    user     = "vmware"
    password = var.app_password
    host     = "${lookup(var.app_vms[count.index], "ipv4_address")}"
  }

  provisioner "file" {
    source      = "html/index.html"
    destination = "/home/vmware/index.html"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.app_password} | sudo -S apt-get update",
      "sudo apt-get install -y apache2",
      "sudo mv /home/vmware/index.html /var/www/html/",
      "sudo sed -i 's/HOSTNAME/${lookup(var.app_vms[count.index], "hostname")}/g' /var/www/html/index.html"
    ]
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
    storage_policy_id       = data.vsphere_storage_policy.db_storage_policy.id
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

# configure basic nsx-t provider settings                                                   ### Addition from stage01 ###
provider "nsxt" {
  host                  = var.nsx_manager
  username              = var.username
  password              = var.password
  allow_unverified_ssl  = true
  max_retries           = 10
  retry_min_delay       = 500
  retry_max_delay       = 5000
  retry_on_status_codes = [429]
}

# define what edge-cluster to use                                                           ### Addition from stage01 ###
data "nsxt_policy_edge_cluster" "ec" {
  display_name = var.nsx_edgecluster
}

# define what overlay transport zone to use                                                 ### Addition from stage01 ###
data "nsxt_policy_transport_zone" "overlay_tz" {
  display_name = var.nsx_overlay_transportzone
}

# define main t0 instance to use                                                            ### Addition from stage01 ###
data "nsxt_policy_tier0_gateway" "tier0_gw" {
  display_name = var.nsx_tier0_gw
}

# create t1 router                                                                          ### Addition from stage01 ###
resource "nsxt_policy_tier1_gateway" "tier1_gw" {
  description               = "Tier-1 provisioned by Terraform"
  display_name              = var.deployment_name
  nsx_id                    = var.deployment_name
  edge_cluster_path         = data.nsxt_policy_edge_cluster.ec.path
  failover_mode             = "PREEMPTIVE"
  default_rule_logging      = "false"
  enable_firewall           = "true"
  enable_standby_relocation = "false"
  tier0_path                = data.nsxt_policy_tier0_gateway.tier0_gw.path
  route_advertisement_types = ["TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]
  pool_allocation           = "ROUTING"
}

# create logical segments                                                                   ### Addition from stage01 ###
resource "nsxt_policy_segment" "segment" {
  display_name        = var.deployment_name
  description         = "Terraform provisioned Segment for ${var.deployment_name}"
  connectivity_path   = resource.nsxt_policy_tier1_gateway.tier1_gw.path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path

  subnet {
    cidr        = var.nsx_segment_cidr
  }
}

# wait for the segment to intitialize, then pass to vsphere_network                         ### Addition from stage01 ###
data "nsxt_policy_segment_realization" "segment" {
  path = nsxt_policy_segment.segment.path
}

# assign the segment to the vsphere_network object.                                         ### Addition from stage01 ###
data "vsphere_network" "network" {
    name = data.nsxt_policy_segment_realization.segment.network_name
    datacenter_id = "${data.vsphere_datacenter.datacenter.id}"
}

# create a NSX-T group of the application servers                                           ### Addition from stage01 ###
resource "nsxt_policy_group" "app_group" {
  display_name = format("%s-%s", var.deployment_name, "app" )
  description  = "Terraform provisioned Group"

  criteria {
    condition {
      key         = "Name"
      member_type = "VirtualMachine"
      operator    = "STARTSWITH"
      value       = format("%s-%s", var.deployment_name, "app" )
    }
  }
}

# create a dynamic NSX-T group of the database servers                                      ### Addition from stage01 ###
resource "nsxt_policy_group" "db_group" {
  display_name = format("%s-%s", var.deployment_name, "db" )
  description  = "Terraform provisioned Group"

  criteria {
    condition {
      key         = "Name"
      member_type = "VirtualMachine"
      operator    = "STARTSWITH"
      value       = format("%s-%s", var.deployment_name, "db" )
    }
  }
}

# create a dynamic nsx-t load balanacer service                                             ### Addition from stage01 ###
resource "nsxt_policy_lb_service" "loadbalancer-service" {
  display_name      = var.deployment_name
  description       = "Terraform provisioned Service"
  connectivity_path = resource.nsxt_policy_tier1_gateway.tier1_gw.path
  size              = "SMALL"
  enabled           = true
  error_log_level   = "ERROR"
  depends_on        = [resource.nsxt_policy_tier1_gateway.tier1_gw]
}

# define what nsx-t application load balancer profile to use, http, tcp etc.                ### Addition from stage01 ###
data "nsxt_policy_lb_app_profile" "loadbalancer-app-profile" {
  type         = "HTTP"
  display_name = "default-http-lb-app-profile"
}

# define a pool of servers that will be load balanced to.                                   ### Addition from stage01 ###
# Instead of assigning one or multiple ip-addreses, 
# we define the nsx-t dynamic group previously created
resource "nsxt_policy_lb_pool" "loadbalancer-pool" {
  display_name         = var.deployment_name
  description          = "Terraform provisioned LB Pool"
  algorithm            = "ROUND_ROBIN"
  min_active_members   = 2
  active_monitor_path = "/infra/lb-monitor-profiles/default-http-lb-monitor"
  member_group {
      group_path = resource.nsxt_policy_group.app_group.path
      allow_ipv4 = true
      port = 80
  }
  snat {
    type = "AUTOMAP"
  }
  tcp_multiplexing_enabled = true
  tcp_multiplexing_number  = 8
}

# create a virtual server, defining the above load balancing profile, pool, etc.            ### Addition from stage01 ###
resource "nsxt_policy_lb_virtual_server" "loadbalancer-virtual-server-http" {
  display_name               = format("%s-%s", var.deployment_name, "http")
  description                = "Terraform provisioned Virtual Server"
  access_log_enabled         = true
  application_profile_path   = data.nsxt_policy_lb_app_profile.loadbalancer-app-profile.path
  enabled                    = true
  ip_address                 = var.app_vip
  ports                      = ["80"]
  default_pool_member_ports  = ["80"]
  service_path               = nsxt_policy_lb_service.loadbalancer-service.path
  max_concurrent_connections = 6
  max_new_connection_rate    = 20
  pool_path                  = nsxt_policy_lb_pool.loadbalancer-pool.path
}
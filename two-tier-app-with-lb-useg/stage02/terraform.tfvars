username = "username@example.com"

deployment_name = "stage02"
vcenter = "sfo-w01-vc01.example.com"
vsphere_datacenter = "sfo-w01-DC"
vsphere_cluster = "sfo-w01-cl01"
vsphere_datastore = "sfo-w01-sfo-w01-vc01-sfo-w01-cl01-vsan01"

nsx_manager = "sfo-w01-nsx01.example.com"
nsx_edgecluster = "sfo-w01-ec02"
nsx_overlay_transportzone = "overlay-tz-sfo-w01-nsx01.example.com"
nsx_tier0_gw = "sfo-w01-ec02-t0-gw01"
nsx_segment_cidr = "172.16.26.1/27"

#app settings
app_cpus = 2
app_memory = 8192
app_disk = 40
app_storage_policy = "sfo-w01-cl01-r5-ftt1-vSAN-Storage-Policy"
app_vip = "172.16.26.10"
app_password = "VMware1!"
app_vms = [
  {
    hostname = "app01"
    ipv4_address = "172.16.26.11"
    ipv4_netmask = "27"
    ipv4_gateway = "172.16.26.1" 
  },
  {
    hostname = "app02"
    ipv4_address = "172.16.26.12"
    ipv4_netmask = "27"
    ipv4_gateway = "172.16.26.1"
  },
  {
    hostname = "app03"
    ipv4_address = "172.16.26.13"
    ipv4_netmask = "27"
    ipv4_gateway = "172.16.26.1"
  }
]

#db settings
db_cpus = 4
db_memory = 8192
db_disk = 40
db_storage_policy = "sfo-w01-cl01-r5-ftt1-vSAN-Storage-Policy"
db_vms = [
  {
    hostname = "db01"
    ipv4_address = "172.16.26.15"
    ipv4_netmask = "27"
    ipv4_gateway = "172.16.26.1" 
  }
]

#common settings
dns_server_list = ["172.16.100.4", "172.16.100.5"]
dns_suffix_list = ["example.com"]
domain = "example.com"
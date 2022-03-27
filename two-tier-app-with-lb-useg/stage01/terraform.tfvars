username = "username@example.com"

deployment_name = "stage01"
vcenter = "sfo-w01-vc01.example.com"
vsphere_datacenter = "sfo-w01-DC"
vsphere_cluster = "sfo-w01-cl01"
vsphere_datastore = "sfo-w01-sfo-w01-vc01-sfo-w01-cl01-vsan01"

#app settings
app_cpus = 2
app_memory = 8192
app_disk = 40
app_storage_policy = "sfo-w01-cl01-r5-ftt1-vSAN-Storage-Policy"
app_vms = [
  {
    hostname = "app01"
    ipv4_address = "172.16.8.101"
    ipv4_netmask = "24"
    ipv4_gateway = "172.16.8.1" 
  },
  {
    hostname = "app02"
    ipv4_address = "172.16.8.102"
    ipv4_netmask = "24"
    ipv4_gateway = "172.16.8.1"
  },
  {
    hostname = "app03"
    ipv4_address = "172.16.8.103"
    ipv4_netmask = "24"
    ipv4_gateway = "172.16.8.1"
  }
]

#db settings
db_cpus = 4
db_memory = 8192
db_disk = 40
db_storage_policy = "sfo-w01-cl01-r1-ftt1-vSAN-Storage-Policy"
db_vms = [
  {
    hostname = "db01"
    ipv4_address = "172.16.8.110"
    ipv4_netmask = "24"
    ipv4_gateway = "172.16.8.1" 
  }
]

#common settings
dns_server_list = ["172.16.100.4", "172.16.100.5"]
dns_suffix_list = ["example.com"]
domain = "example.com"
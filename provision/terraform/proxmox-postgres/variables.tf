
variable "common" {
  type = map(string)
  default = {
    os_type         = "ubuntu"
    clone           = "ubuntu-20-04-cloudimg"
    search_domain   = ""  # Ensure this one is blank or coredns will not wor properly
    node_fqdn       = "cs.aml.ink"
    nameserver      = "192.168.30.1"
    ceph_nameserver = "192.168.25.1"
    username        = "dfroberg"
    gw              = "192.168.30.1"
    ceph_gw         = "192.168.25.1"
  }
}

variable "dbs" {
  type = map(map(string))
  default = {
    postgres = {
      tags        ="k3s,db"
      id          = 4009
      primary_ip  = "192.168.30.18"
      cidr        = "192.168.30.18/24"
      cidr6       = "fe80::6ab5:99ff:feb3:dafa"
      ceph_primary_ip  = "192.168.25.18"
      ceph_cidr   = "192.168.25.18/24"
      sockets     = 1
      cpulimit    = 4
      vcpus       = 8
      cores       = 8
      macaddr     = "68:b5:99:b3:da:fa"
      ceph_macaddr = "68:b5:99:b3:db:fa"
      memory      = 4096
      disk        = "9420M"
      disk_slot   = 0
      disk_iothread = 1
      target_node = "pve"
      storage_pool     = "vm-pool"
      resource_pool_name = "High"
    },
  }
}

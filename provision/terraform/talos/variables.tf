
variable "common" {
  type = map(string)
  default = {
    os_type         = "cloud-init"
    clone           = "talos-1-0-5-amd64"
    search_domain   = ""  # Ensure this one is blank or coredns will not wor properly
    node_fqdn       = "cs.aml.ink"
    nameserver      = "192.168.30.1"
    username        = "dfroberg"
    gw              = "192.168.30.1"
  }
}

variable "cps" {
  type = map(map(string))
  default = {
    cp01 = {
      tags        ="k3s,controlplane,talos"
      id          = 6010
      primary_ip  = "192.168.30.10"
      cidr        = "192.168.30.10/24"
      sockets     = 1
      cpulimit    = 4
      vcpus       = 4
      cores       = 4
      macaddr     = "68:b5:99:b3:dd:01"
      memory      = 8*1024
      disk        = "29900M"
      disk_slot   = 0
      disk_iothread = 0
      target_node = "pve"
      storage_pool     = "vm-pool"
      resource_pool_name = "High"
    },
    cp02 = {
      tags        ="k3s,controlplane,talos"
      id          = 6011
      primary_ip  = "192.168.30.11"
      cidr        = "192.168.30.11/24"
      sockets     = 1
      cpulimit    = 4
      vcpus       = 4
      cores       = 4
      macaddr     = "68:b5:99:b3:dd:02"
      memory      = 8*1024
      disk        = "29900M"
      disk_slot   = 0
      disk_iothread = 0
      target_node = "pve"
      storage_pool     = "vm-pool"
      resource_pool_name = "High"
    },
    cp03 = {
      tags        ="k3s,controlplane,talos"
      id          = 6012
      primary_ip  = "192.168.30.12"
      cidr        = "192.168.30.12/24"
      sockets     = 1
      cpulimit    = 4
      vcpus       = 4
      cores       = 4
      macaddr     = "68:b5:99:b3:dd:03"
      memory      = 8*1024
      disk        = "29900M"
      disk_slot   = 0
      disk_iothread = 0
      target_node = "pve"
      storage_pool     = "vm-pool"
      resource_pool_name = "High"
    },
  }
}
variable "workers" {
  type = map(map(string))
  default = {
    node01 = {
      tags        ="k3s,worker,talos"
      id          = 6021
      primary_ip  = "192.168.30.20"
      cidr        = "192.168.30.20/24"
      sockets     = 1
      cpulimit    = 8
      vcpus       = 8
      cores       = 8
      macaddr     = "68:b5:99:b3:de:01"
      memory      = 16*1024
      disk        = "29900M"
      disk_slot   = 0
      disk_iothread = 0
      target_node = "pve"
      storage_pool     = "vm-pool"
      resource_pool_name = "High"
    },
    node02 = {
      tags        ="k3s,worker,talos"
      id          = 6022
      primary_ip  = "192.168.30.21"
      cidr        = "192.168.30.21/24"
      sockets     = 1
      cpulimit    = 8
      vcpus       = 8
      cores       = 8
      macaddr     = "68:b5:99:b3:de:02"
      memory      = 16*1024
      disk        = "29900M"
      disk_slot   = 0
      disk_iothread = 0
      target_node = "pve"
      storage_pool     = "vm-pool"
      resource_pool_name = "High"
    },
    node03 = {
      tags        ="k3s,worker,talos"
      id          = 6023
      primary_ip  = "192.168.30.22"
      cidr        = "192.168.30.22/24"
      sockets     = 1
      cpulimit    = 8
      vcpus       = 8
      cores       = 8
      macaddr     = "68:b5:99:b3:de:03"
      memory      = 16*1024
      disk        = "29900M"
      disk_slot   = 0
      disk_iothread = 0
      target_node = "pve"
      storage_pool     = "vm-pool"
      resource_pool_name = "High"
    },
    node04 = {
      tags        ="k3s,worker,talos"
      id          = 6024
      primary_ip  = "192.168.30.23"
      cidr        = "192.168.30.23/24"
      sockets     = 1
      cpulimit    = 8
      vcpus       = 8
      cores       = 8
      macaddr     = "68:b5:99:b3:de:04"
      memory      = 16*1024
      disk        = "29900M"
      disk_slot   = 0
      disk_iothread = 0
      target_node = "pve"
      storage_pool     = "vm-pool"
      resource_pool_name = "High"
    },
  }
}


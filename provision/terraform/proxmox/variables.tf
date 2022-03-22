
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
      target_node = "pve"
      storage_pool     = "vm-data"
      resource_pool_name = "High"
    },
  }
}
variable "masters" {
  type = map(map(string))
  default = {
    master01 = {
      id          = 4010
      primary_ip  = "192.168.30.50"
      cidr        = "192.168.30.50/24"
      cidr6       = "fe80::6ab5:99ff:feb3:da01"
      ceph_primary_ip  = "192.168.25.50"
      ceph_cidr   = "192.168.25.50/24"
      sockets     = 1
      cpulimit    = 4
      vcpus       = 4
      cores       = 8
      macaddr     = "68:b5:99:b3:da:01"
      ceph_macaddr = "68:b5:99:b3:db:01"
      memory      = 10240
      disk        = "29900M"
      disk_slot   = 0
      target_node = "pve"
      storage_pool     = "vm-data"
      resource_pool_name = "High"
    },
    master02 = {
      id          = 4011
      primary_ip  = "192.168.30.51"
      cidr        = "192.168.30.51/24"
      cidr6       = "fe80::6ab5:99ff:feb3:da02"
      ceph_primary_ip  = "192.168.25.51"
      ceph_cidr   = "192.168.25.51/24"
      sockets     = 1
      cpulimit    = 4
      vcpus       = 4
      cores       = 8
      macaddr     = "68:b5:99:b3:da:02"
      ceph_macaddr = "68:b5:99:b3:db:02"
      memory      = 10240
      disk        = "29900M"
      disk_slot   = 0
      target_node = "pve"
      storage_pool     = "vm-data"
      resource_pool_name = "High"
    },
    master03 = {
      id          = 4012
      primary_ip  = "192.168.30.52"
      cidr        = "192.168.30.52/24"
      cidr6       = "fe80::6ab5:99ff:feb3:db03"
      ceph_primary_ip  = "192.168.25.52"
      ceph_cidr   = "192.168.25.52/24"
      sockets     = 1
      cpulimit    = 4
      vcpus       = 4
      cores       = 8
      macaddr     = "68:b5:99:b3:da:03"
      ceph_macaddr = "68:b5:99:b3:db:03"
      memory      = 10240
      disk        = "29900M"
      disk_slot   = 0
      target_node = "pve"
      storage_pool     = "vm-data"
      resource_pool_name = "High"
    }
  }
}
variable "storage" {
  type = map(map(string))
  default = {
    storage01 = {
      id          = 4030
      primary_ip  = "192.168.30.53"
      cidr        = "192.168.30.53/24"
      cidr6       = "fe80::6ab5:99ff:feb3:db1a"
      ceph_primary_ip  = "192.168.25.53"
      ceph_cidr   = "192.168.25.53/24"
      sockets     = 1
      cpulimit    = 4
      vcpus       = 4
      cores       = 8
      macaddr     = "68:b5:99:b3:da:1a"
      ceph_macaddr = "68:b5:99:b3:db:1a"
      memory      = 4096
      disk        = "29900M"
      disk_slot   = 0
      storage_disk = "50G"
      storage_disk_slot   = 1
      target_node = "pve"
      storage_pool     = "vm-data"
      storage_pool_disk_storage = "vm-data"
      resource_pool_name = "Normal"
    },
    storage02 = {
      id          = 4031
      primary_ip  = "192.168.30.54"
      cidr        = "192.168.30.54/24"
      cidr6       = "fe80::6ab5:99ff:feb3:db1b"
      ceph_primary_ip  = "192.168.25.54"
      ceph_cidr   = "192.168.25.54/24"
      sockets     = 1
      cpulimit    = 4
      vcpus       = 4
      cores       = 8
      macaddr     = "68:b5:99:b3:da:1b"
      ceph_macaddr = "68:b5:99:b3:db:1b"
      memory      = 4096
      disk        = "29900M"
      disk_slot   = 0
      storage_disk = "50G"
      storage_disk_slot   = 1
      target_node = "pve"
      storage_pool     = "vm-data"
      storage_pool_disk_storage = "vm-data"
      resource_pool_name = "Normal"
    },
    storage03 = {
      id          = 4032
      primary_ip  = "192.168.30.55"
      cidr        = "192.168.30.55/24"
      cidr6       = "fe80::6ab5:99ff:feb3:da1c"
      ceph_primary_ip  = "192.168.25.55"
      ceph_cidr   = "192.168.25.55/24"
      sockets     = 1
      cpulimit    = 4
      vcpus       = 4
      cores       = 8
      macaddr     = "68:b5:99:b3:da:1c"
      ceph_macaddr = "68:b5:99:b3:db:1c"
      memory      = 4096
      disk        = "29900M"
      disk_slot   = 0
      storage_disk = "50G"
      storage_disk_slot   = 1
      target_node = "pve"
      storage_pool     = "vm-data"
      storage_pool_disk_storage = "vm-data"
      resource_pool_name = "Normal"
    },
  }
}
variable "workers" {
  type = map(map(string))
  default = {
    worker01 = {
      id          = 4020
      primary_ip  = "192.168.30.56"
      cidr        = "192.168.30.56/24"
      cidr6       = "fe80::6ab5:99ff:feb3:db0a"
      ceph_primary_ip  = "192.168.25.56"
      ceph_cidr   = "192.168.25.56/24"
      sockets     = 4
      cpulimit    = 4
      vcpus       = 8
      cores       = 8
      macaddr     = "68:b5:99:b3:da:0a"
      ceph_macaddr = "68:b5:99:b3:db:0a"
      memory      = 12288
      disk        = "60620M"
      disk_slot   = 0
      target_node = "pve"
      storage_pool     = "vm-data"
      resource_pool_name = "Normal"
    },
    worker02 = {
      id          = 4021
      primary_ip  = "192.168.30.57"
      cidr        = "192.168.30.57/24"
      cidr6       = "fe80::6ab5:99ff:feb3:da0b"
      ceph_primary_ip  = "192.168.25.57"
      ceph_cidr   = "192.168.25.57/24"
      sockets     = 4
      cpulimit    = 4
      vcpus       = 8
      cores       = 8
      macaddr     = "68:b5:99:b3:da:0b"
      ceph_macaddr = "68:b5:99:b3:db:0b"
      memory      = 12288
      disk        = "60620M"
      disk_slot   = 0
      target_node = "pve"
      storage_pool     = "vm-data"
      resource_pool_name = "Normal"
    },
    worker03 = {
      id          = 4022
      primary_ip  = "192.168.30.58"
      cidr        = "192.168.30.58/24"
      cidr6       = "fe80::6ab5:99ff:feb3:da0c"
      ceph_primary_ip  = "192.168.25.58"
      ceph_cidr   = "192.168.25.58/24"
      sockets     = 4
      cpulimit    = 4
      vcpus       = 8
      cores       = 8
      macaddr     = "68:b5:99:b3:da:0c"
      ceph_macaddr = "68:b5:99:b3:db:0c"
      memory      = 12288
      disk        = "60620M"
      disk_slot   = 0
      target_node = "pve"
      storage_pool= "vm-data"
      resource_pool_name = "Normal"
    },
  }
}



variable "common" {
  type = map(string)
  default = {
    os_type       = "ubuntu"
    clone         = "ubuntu-20-04-cloudimg"
    search_domain = ""  # Ensure this one is blank or coredns will not wor properly
    nameserver    = "192.168.30.1"
    username      = "dfroberg"
  }
}

variable "dbs" {
  type = map(map(string))
  default = {
    postgres = {
      id          = 4009
      cidr        = "192.168.30.18/24"
      primary_ip  = "192.168.30.18"
      ceph_cidr   = "192.168.25.18/24"
      sockets     = 1
      cpulimit    = 4
      vcpus       = 8
      cores       = 8
      gw          = "192.168.30.1"
      macaddr     = "68:b5:99:b3:da:fa"
      memory      = 4096
      disk        = "9420M"
      disk_slot   = 0
      target_node = "pve"
      storage_pool     = "vm-data"
    },
  }
}

variable "masters" {
  type = map(map(string))
  default = {
    k8s-master01 = {
      id          = 4010
      cidr        = "192.168.30.50/24"
      primary_ip  = "192.168.30.50"
      ceph_cidr   = "192.168.25.50/24"
      sockets     = 1
      cpulimit    = 4
      vcpus       = 8
      cores       = 8
      gw          = "192.168.30.1"
      macaddr     = "68:b5:99:b3:da:01"
      memory      = 10240
      disk        = "29900M"
      disk_slot   = 0
      target_node = "pve"
      storage_pool     = "vm-data"
    },
    k8s-master02 = {
      id          = 4011
      cidr        = "192.168.30.51/24"
      primary_ip  = "192.168.30.51"
      ceph_cidr   = "192.168.25.51/24"
      sockets     = 1
      cpulimit    = 4
      vcpus       = 8
      cores       = 8
      gw          = "192.168.30.1"
      macaddr     = "68:b5:99:b3:da:02"
      memory      = 10240
      disk        = "29900M"
      disk_slot   = 0
      target_node = "pve"
      storage_pool     = "vm-data"
    },
    k8s-master03 = {
      id          = 4012
      cidr        = "192.168.30.52/24"
      primary_ip  = "192.168.30.52"
      ceph_cidr   = "192.168.25.52/24"
      sockets     = 1
      cpulimit    = 4
      vcpus       = 8
      cores       = 8
      gw          = "192.168.30.1"
      macaddr     = "68:b5:99:b3:da:03"
      memory      = 10240
      disk        = "29900M"
      disk_slot   = 0
      target_node = "pve"
      storage_pool     = "vm-data"
    }
  }
}
variable "storage" {
  type = map(map(string))
  default = {
    k8s-storage01 = {
      id          = 4030
      cidr        = "192.168.30.53/24"
      primary_ip  = "192.168.30.53"
      ceph_cidr   = "192.168.25.53/24"
      sockets     = 1
      cpulimit    = 4
      vcpus       = 8
      cores       = 8
      gw          = "192.168.30.1"
      macaddr     = "68:b5:99:b3:da:1A"
      memory      = 4096
      disk        = "29900M"
      disk_slot   = 0
      storage_disk= "50G"
      storage_disk_slot   = 1
      target_node = "pve"
      storage_pool     = "vm-data"
      storage_pool_disk_storage = "vm-data"
    },
    k8s-storage02 = {
      id          = 4031
      cidr        = "192.168.30.54/24"
      primary_ip  = "192.168.30.54"
      ceph_cidr   = "192.168.25.54/24"
      sockets     = 1
      cpulimit    = 4
      vcpus       = 8
      cores       = 8
      gw          = "192.168.30.1"
      macaddr     = "68:b5:99:b3:da:1B"
      memory      = 4096
      disk        = "29900M"
      disk_slot   = 0
      storage_disk= "50G"
      storage_disk_slot   = 1
      target_node = "pve"
      storage_pool     = "vm-data"
      storage_pool_disk_storage = "vm-data"
    },
    k8s-storage03 = {
      id          = 4032
      cidr        = "192.168.30.55/24"
      primary_ip  = "192.168.30.55"
      ceph_cidr   = "192.168.25.55/24"
      sockets     = 1
      cpulimit    = 4
      vcpus       = 8
      cores       = 8
      gw          = "192.168.30.1"
      macaddr     = "68:b5:99:b3:da:1C"
      memory      = 4096
      disk        = "29900M"
      disk_slot   = 0
      storage_disk= "50G"
      storage_disk_slot   = 1
      target_node = "pve"
      storage_pool     = "vm-data"
      storage_pool_disk_storage = "vm-data"
    },
  }
}
variable "workers" {
  type = map(map(string))
  default = {
    k8s-worker01 = {
      id          = 4020
      cidr        = "192.168.30.56/24"
      primary_ip  = "192.168.30.56"
      ceph_cidr   = "192.168.25.56/24"
      sockets     = 4
      cpulimit    = 4
      vcpus       = 32
      cores       = 8
      gw          = "192.168.30.1"
      macaddr     = "68:b5:99:b3:da:0A"
      memory      = 20480
      disk        = "60620M"
      disk_slot   = 0
      target_node = "pve"
      storage_pool     = "vm-data"
    },
    k8s-worker02 = {
      id          = 4021
      cidr        = "192.168.30.57/24"
      primary_ip  = "192.168.30.57"
      ceph_cidr   = "192.168.25.57/24"
      sockets     = 4
      cpulimit    = 4
      vcpus       = 32
      cores       = 8
      gw          = "192.168.30.1"
      macaddr     = "68:b5:99:b3:da:0B"
      memory      = 20480
      disk        = "60620M"
      disk_slot   = 0
      target_node = "pve"
      storage_pool     = "vm-data"
    },
    k8s-worker03 = {
      id          = 4022
      cidr        = "192.168.30.58/24"
      primary_ip  = "192.168.30.58"
      ceph_cidr   = "192.168.25.58/24"
      sockets     = 4
      cpulimit    = 4
      vcpus       = 32
      cores       = 8
      gw          = "192.168.30.1"
      macaddr     = "68:b5:99:b3:da:0C"
      memory      = 20480
      disk        = "60620M"
      disk_slot   = 0
      target_node = "pve"
      storage_pool= "vm-data"
    },
  }
}


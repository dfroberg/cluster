
variable "common" {
  type = map(string)
  default = {
    os_type       = "ubuntu"
    clone         = "ubuntu-20.04-cloudimg"
    search_domain = "cs.aml.ink"
    nameserver    = "192.168.30.1"
    username      = "dfroberg"
  }
}

variable "masters" {
  type = map(map(string))
  default = {
    k8s-master01 = {
      id          = 4010
      cidr        = "192.168.30.10/24"
      ceph_cidr   = "192.168.25.10/24"
      cores       = 8
      gw          = "192.168.30.1"
      macaddr     = "68:b5:99:b3:da:01"
      memory      = 24576
      disk        = "30G"
      target_node = "pve"
    },
    k8s-master02 = {
      id          = 4011
      cidr        = "192.168.30.11/24"
      ceph_cidr   = "192.168.25.11/24"
      cores       = 8
      gw          = "192.168.30.1"
      macaddr     = "68:b5:99:b3:da:02"
      memory      = 24576
      disk        = "30G"
      target_node = "pve2"
    },
    k8s-master03 = {
      id          = 4012
      cidr        = "192.168.30.12/24"
      ceph_cidr   = "192.168.25.12/24"
      cores       = 8
      gw          = "192.168.30.1"
      macaddr     = "68:b5:99:b3:da:03"
      memory      = 24576
      disk        = "30G"
      target_node = "pve3"
    }
  }
}

variable "workers" {
  type = map(map(string))
  default = {
    k8s-worker01 = {
      id          = 4020
      cidr        = "192.168.30.20/24"
      ceph_cidr   = "192.168.25.20/24"
      cores       = 8
      gw          = "192.168.30.1"
      macaddr     = "68:b5:99:b3:da:0A"
      memory      = 24576
      disk        = "30G"
      target_node = "pve"
    },
    k8s-worker02 = {
      id          = 4021
      cidr        = "192.168.30.21/24"
      ceph_cidr   = "192.168.25.21/24"
      cores       = 8
      gw          = "192.168.30.1"
      macaddr     = "68:b5:99:b3:da:0B"
      memory      = 24576
      disk        = "30G"
      target_node = "pve2"
    },
    k8s-worker03 = {
      id          = 4022
      cidr        = "192.168.30.22/24"
      ceph_cidr   = "192.168.25.22/24"
      cores       = 8
      gw          = "192.168.30.1"
      macaddr     = "68:b5:99:b3:da:0C"
      memory      = 24576
      disk        = "30G"
      target_node = "pve3"
    },
  }
}

variable "storage" {
  type = map(map(string))
  default = {
    k8s-storage01 = {
      id          = 4030
      cidr        = "192.168.30.30/24"
      ceph_cidr   = "192.168.25.30/24"
      cores       = 8
      gw          = "192.168.30.1"
      macaddr     = "68:b5:99:b3:da:1A"
      memory      = 24576
      disk        = "30G"
      storage_disk= "100G"
      target_node = "pve"
    },
    k8s-storage02 = {
      id          = 4031
      cidr        = "192.168.30.31/24"
      ceph_cidr   = "192.168.25.31/24"
      cores       = 8
      gw          = "192.168.30.1"
      macaddr     = "68:b5:99:b3:da:1B"
      memory      = 24576
      disk        = "30G"
      storage_disk= "100G"
      target_node = "pve2"
    },
    k8s-storage03 = {
      id          = 4032
      cidr        = "192.168.30.32/24"
      ceph_cidr   = "192.168.25.32/24"
      cores       = 8
      gw          = "192.168.30.1"
      macaddr     = "68:b5:99:b3:da:1C"
      memory      = 24576
      disk        = "30G"
      storage_disk= "100G"
      target_node = "pve3"
    },
  }
}
packer {
  required_plugins {
    proxmox = {
      version = " >= 1.0.1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "proxmox-ubuntu-20" {
  proxmox_url = "https://192.168.3.100:8006/api2/json"
  vm_name     = "packer-ubuntu-20"
  iso_url      = "http://192.168.3.100/ubuntu-20.04.3-live-server-amd64.iso"
  iso_checksum = "f8e3086f3cea0fb3fefb29937ab5ed9d19e767079633960ccb50e76153effc98"
  username         = "${var.pm_user}"
  password         = "${var.pm_pass}"
  token            = "${var.pm_token}"
  node             = "pve"
  iso_storage_pool = "local"

  ssh_username           = "${var.ssh_user}"
  ssh_password           = "${var.ssh_pass}"
  ssh_timeout            = "24h"
  ssh_pty                = true
  ssh_handshake_attempts = 20

  boot_wait      = "5s"
  # http_directory = "http" # Starts a local http server, serves Preseed file
  boot_command = [
    "<esc><wait><esc><wait><f6><wait><esc><wait>",
    "<bs><bs><bs><bs><bs>",
    "ip=${cidrhost("192.168.0.0/24", 9)}::${cidrhost("192.168.0.0/24", 1)}:${cidrnetmask("192.168.0.0/24")}::::${cidrhost("192.168.0.0/24", 1)} ",
    # " autoinstall ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/http/ ", #Dont specify the file
    " autoinstall ds=nocloud-net;s=http://192.168.0.144:80/preseed/ubuntu-20/ ", #Dont specify the file
    "boot",
    "--- <enter>"
  ]

  insecure_skip_tls_verify = true

  template_name        = "packer-ubuntu-20"
  template_description = "packer generated ubuntu-20.04.3-server-amd64"
  unmount_iso          = true

  pool       = "packer"
  memory     = 4096
  cores      = 1
  sockets    = 1
  os         = "l26"
  qemu_agent = true
  disks {
    type              = "scsi"
    disk_size         = "30G"
    storage_pool      = "local-lvm"
    storage_pool_type = "lvm"
    format            = "raw"
  }
  network_adapters {
    bridge   = "vmbr0"
    model    = "virtio"
    firewall = true
  }
}

build {
  sources = ["source.proxmox-iso.proxmox-ubuntu-20"]
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "ls /"
    ]
  }
}
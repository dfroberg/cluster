resource "proxmox_vm_qemu" "kube-master" {
  for_each = var.masters

  name        = each.key
  target_node = each.value.target_node
  agent       = 1
  clone       = var.common.clone
  vmid        = each.value.id
  memory      = each.value.memory
  cores       = each.value.cores
  vga {
    type = "qxl"
  }
  network {
    model    = "virtio"
    macaddr  = each.value.macaddr
    bridge   = "vmbr30"
    firewall = true
  }
   network {
    model    = "virtio"
    bridge   = "vmbr25"
  }
  disk {
    type    = "scsi"
    storage = "nas-zfs"
    size    = each.value.disk
    format  = "raw"
    ssd     = 1
    discard = "on"
  }
  serial {
    id = 0
    type = "socket"
  }
  bootdisk     = "scsi0"
  scsihw       = "virtio-scsi-pci"
  os_type      = "cloud-init"
  ipconfig0    = "ip=${each.value.cidr},gw=${each.value.gw}"
  ipconfig1    = "ip=${each.value.ceph_cidr}"
  cicustom     = "user=nas-nfs:snippets/vm-${each.value.id}-user-data.yml,meta=nas-nfs:snippets/vm-${each.value.id}-meta-data.yml,network=nas-nfs:snippets/vm-${each.value.id}-network-data.yml"
  #ciuser       = "dfroberg"
  #cipassword   = data.sops_file.secrets.data["k8s.user_password"]
  #searchdomain = var.common.search_domain
  #nameserver   = var.common.nameserver
  #sshkeys      = data.sops_file.secrets.data["k8s.ssh_key"]
  cloudinit_cdrom_storage = "nas-nfs"
  numa         = "1"
  hotplug      = "disk,network,usb,memory,cpu"
}

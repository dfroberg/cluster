resource "proxmox_vm_qemu" "kube-storage" {
  for_each = var.storage

  name        = each.key
  target_node = each.value.target_node
  agent       = 1
  clone       = var.common.clone
  vmid        = each.value.id
  memory      = each.value.memory
  sockets     = each.value.sockets
  cores       = each.value.cores
  vcpus       = each.value.vcpus
  cpulimit    = each.value.cpulimit
  vga {
    type = "qxl"
  }
  network {
    model    = "virtio"
    macaddr  = each.value.macaddr
    bridge   = "vmbr30"
    firewall = false
  }
  network {
    model    = "virtio"
    bridge   = "vmbr25"
  }
  disk {
    slot    = each.value.disk_slot # needed to prevent recreate
    type    = "scsi"
    storage = each.value.storage_pool
    size    = each.value.disk
    format  = "raw"
    ssd     = 1
    discard = "on"
  }
  disk {
    slot    = each.value.storage_disk_slot # needed to prevent recreate
    type    = "scsi"
    storage = each.value.storage_pool_disk_storage
    size    = each.value.storage_disk
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
  #cicustom     = "user=nas-nfs:snippets/vm-${each.value.id}-user-data.yaml,meta=nas-nfs:snippets/vm-${each.value.id}-meta-data.yaml,network=nas-nfs:snippets/vm-${each.value.id}-network-data.yaml"
  ciuser       = "dfroberg"
  cipassword   = data.sops_file.secrets.data["k8s.user_password"]
  searchdomain = var.common.search_domain
  nameserver   = var.common.nameserver
  sshkeys      = data.sops_file.secrets.data["k8s.ssh_key"]
  numa         = "1"
  hotplug      = "disk,network,usb,memory,cpu"
}

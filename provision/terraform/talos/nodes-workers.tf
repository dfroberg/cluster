resource "proxmox_vm_qemu" "talos-workers" {
  for_each = var.workers
  name        = each.key
  tags        = each.value.tags
  target_node = each.value.target_node
  desc        = "Talos Node ${each.key}"
  pool        = "cluster2"
  agent       = 1
  clone       = var.common.clone
  vmid        = each.value.id
  bios        = "ovmf"
  #args        = "-cpu 'kvm64-x86_64-cpu,+ssse3,+sse4.1,+sse4.2,+x2apic'" # -smbios type=1,serial=ds=nocloud-net;s=http://10.10.0.1/configs/"
  #qemu_os     = "l26"
  onboot      = true
  #balloon     = 0
  memory      = each.value.memory
  sockets     = each.value.sockets
  cores       = each.value.cores
  vcpus       = each.value.vcpus
  #cpulimit    = each.value.cpulimit
  bootdisk     = "virtio0"
  scsihw       = "virtio-scsi-pci"
  os_type      = "cloud-init"
  numa         = "1"
  hotplug      = "disk,network,usb,memory,cpu"
  #ci_wait      = 45
  cicustom     = "user=nas-nfs:snippets/vm-${each.value.id}-user-data.yaml,meta=nas-nfs:snippets/vm-${each.value.id}-meta-data.yaml,network=nas-nfs:snippets/vm-${each.value.id}-network-data.yaml"
  cloudinit_cdrom_storage = "nas-nfs"

  # Nonsense Values
  #
  disk_gb                   = null
  # Depnds
  depends_on = [null_resource.cloud_init_workers_config_files,local_file.cloud_init_workers_user_data_file,local_file.cloud_init_workers_meta_data_file,local_file.cloud_init_workers_network_data_file]

  vga {
    type = "qxl"
    memory = 4
  }
  network {
    model    = "virtio"
    macaddr  = each.value.macaddr
    bridge   = "vmbr30"
    firewall = false
    mtu      = 1500
    queues   = 0
    rate     = 0
  }
  disk {
    slot    = each.value.disk_slot # needed to prevent recreate
    type    = "virtio"
    storage = each.value.storage_pool
    #storage_type = "rbd"
    size    = each.value.disk
    iothread= each.value.disk_iothread
    format  = "raw"
    #ssd     = 1
    discard = "on"
    cache   = "writeback"
    #volume  = "${each.value.storage_pool}:vm-${each.value.id}-disk-1"
  }
  /* disk {
    cache        = "none"
    file         = "vm-${each.value.id}-cloudinit"
    format       = "raw"
    media        = "cdrom"
    size         = "4M"
    slot         = 1
    ssd          = 0
    storage      = "nas-nfs"
    type         = "scsi"
    volume       = "nas-nfs:vm-${each.value.id}-cloudinit"
  } */
  serial {
    id = 0
    type = "socket"
  }
  # Prevents recreate
  lifecycle {
    ignore_changes = [disk_gb, qemu_os, args, clone, hagroup, target_node, full_clone]
  }
  timeouts {
    create = "10m"
    delete = "20m"
  }
}

resource "proxmox_vm_qemu" "kube-master" {
  for_each = var.masters
  name        = each.key
  tags        = each.value.tags
  target_node = each.value.target_node
  desc        = "Master Node ${each.key}"
  pool        = "cluster1"
  agent       = 1
  clone       = var.common.clone
  vmid        = each.value.id
  bios        = "ovmf"
  #qemu_os     = "l26"
  onboot      = true
  oncreate    = false
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
  #ipconfig0    = "ip=${each.value.cidr},gw=${var.common.gw}"
  #ipconfig1    = "ip=${each.value.ceph_cidr},gw=${var.common.ceph_gw}"
  #ciuser       = "dfroberg"
  #cipassword   = data.sops_file.secrets.data["k8s.user_password"]
  #searchdomain = var.common.search_domain
  #nameserver   = var.common.nameserver
  #sshkeys      = data.sops_file.secrets.data["k8s.ssh_key"]#
  # Nonsense Values
  #
  disk_gb                   = null
  # Depnds
  depends_on = [null_resource.cloud_init_config_files,local_file.cloud_init_user_data_file,local_file.cloud_init_meta_data_file,local_file.cloud_init_network_data_file]

  vga {
    type = "qxl"
    memory = 4
  }
  network {
    model    = "virtio"
    macaddr  = each.value.macaddr
    bridge   = "vmbr0"
    tag      = 30
    firewall = false
    mtu      = 1500
    queues   = 0
    rate     = 0
  }
  /* network {
    model    = "virtio"
    macaddr  = each.value.ceph_macaddr
    bridge   = "vmbr25"
    firewall = false
    mtu      = 9000
    queues   = 0
    rate     = 0
  } */
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
  }
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


  # Fix cloud-init cdrom and start the vm
  # Requires the oncreate = false flag to be set
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = data.sops_file.secrets.data["proxmox.user"]
      host     = data.sops_file.secrets.data["proxmox.pm_host"]
      port     = 22
      private_key = "${file("/home/dfroberg/.ssh/id_rsa")}"
      agent = false
      timeout = "5m"
    }
    inline = [
      "sed -i 's/ide2/scsi1/g' /etc/pve/qemu-server/${each.value.id}.conf",
      "qm start ${each.value.id}",
      "sleep 120",
      "exit 0"
    ]
  }
  # Additional service setup
  connection {
    user        = "${data.sops_file.global_secrets.data["ssh.username"]}"
    type        = "ssh"
    private_key = file(data.sops_file.global_secrets.data["ssh.private_keyfile"])
    timeout     = "25m"
    host        = each.value.primary_ip
  }
  provisioner "file" {
    content     = templatefile("files/fstab.tpl", {
      version = 14
      nas_path = data.sops_file.global_secrets.data["nas.nas_path"]
      nas_ip   = data.sops_file.global_secrets.data["nas.nas_ip"]
      username = data.sops_file.global_secrets.data["nas.user"]
      password = data.sops_file.global_secrets.data["nas.password"]
      })
    destination = "/home/dfroberg/fstab.txt"
  }
  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "sleep 30",
      "echo '**************************************************** BEGIN ************************************************'",
      "sudo mkdir -p /mnt/backups",
      "sudo cat /home/dfroberg/fstab.txt | sudo tee -a /etc/fstab",
      #"sudo -i sed -Ei 's/^.* (ecdsa-sha2-(nistp384|nistp521)|ssh-(ed25519|dss|rsa))/\1/' /root/.ssh/authorized_keys",
      "echo '*********************************************** UPGRADE & REBOOT *******************************************'",
      "sudo apt upgrade -y && sudo shutdown -r",
      "echo '***************************************************** DONE *************************************************'",
      "exit 0"
    ]
  }
}

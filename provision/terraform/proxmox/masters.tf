resource "proxmox_vm_qemu" "kube-master" {
  for_each = var.masters

  name        = each.key
  target_node = each.value.target_node
  agent       = 1
  clone       = var.common.clone
  vmid        = each.value.id
  memory      = each.value.memory
  sockets     = each.value.sockets
  cores       = each.value.cores
  vcpus       = each.value.vcpus
  #cpulimit    = each.value.cpulimit
  balloon     = 0
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
  }
  network {
    model    = "virtio"
    macaddr  = each.value.ceph_macaddr
    bridge   = "vmbr25"
    firewall = false
    mtu      = 9000
  }
  disk {
    slot    = each.value.disk_slot # needed to prevent recreate
    type    = "scsi"
    storage = each.value.storage_pool
    size    = each.value.disk
    iothread= each.value.disk_iothread
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
  #ipconfig0    = "ip=${each.value.cidr},gw=${var.common.gw}"
  #ipconfig1    = "ip=${each.value.ceph_cidr},gw=${var.common.ceph_gw}"
  cicustom     = "user=nas-nfs:snippets/vm-${each.value.id}-user-data.yaml,meta=nas-nfs:snippets/vm-${each.value.id}-meta-data.yaml,network=nas-nfs:snippets/vm-${each.value.id}-network-data.yaml"
  cloudinit_cdrom_storage = "nas-nfs"
  #ciuser       = "dfroberg"
  #cipassword   = data.sops_file.secrets.data["k8s.user_password"]
  #searchdomain = var.common.search_domain
  #nameserver   = var.common.nameserver
  #sshkeys      = data.sops_file.secrets.data["k8s.ssh_key"]
  numa         = "1"
  hotplug      = "disk,network,usb,memory,cpu"

  # Additional service setup
  connection {
    user        = "${data.sops_file.global_secrets.data["k8s.ssh_username"]}"
    type        = "ssh"
    private_key = file("/home/${data.sops_file.global_secrets.data["k8s.ssh_username"]}/.ssh/id_rsa")
    timeout     = "20m"
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
      "sudo -i sed -Ei 's/^.* (ecdsa-sha2-(nistp384|nistp521)|ssh-(ed25519|dss|rsa))/\1/' /root/.ssh/authorized_keys",
      "echo '*********************************************** UPGRADE & REBOOT *******************************************'",
      "sudo apt upgrade -y && sudo shutdown -r",
      "echo '***************************************************** DONE *************************************************'",
      "exit 0"
    ]
  }
}

resource "proxmox_lxc" "kube-worker" {
  for_each    = var.workers
  vmid        = each.value.id
  hostname    = each.key
  ostemplate  = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  ostype      = "ubuntu"
  arch        = "amd64"
  unprivileged  = false
  cmode       = "shell"
  tags        = each.value.tags
  target_node = each.value.target_node
  onboot      = true
  start       = true
  startup     = "order=${each.value.start_order},up=60,down=60"
  memory      = each.value.memory
  swap        = 0
  cores       = each.value.cores
  #cpulimit    = each.value.cpulimit
  password   = data.sops_file.secrets.data["k8s.user_password"]
  searchdomain = var.common.search_domain
  nameserver   = var.common.nameserver
  ssh_public_keys = data.sops_file.secrets.data["k8s.ssh_key"]

  features {
    fuse    = true
    nesting = true
    keyctl  = true
    mknod   = true
    mount   = "nfs;cifs"
  }
  // Terraform will crash without rootfs defined
  rootfs {
    storage = each.value.storage_pool
    size    = each.value.disk
  }
  // NFS share mounted on host
  mountpoint {
    key     = "1"
    slot    = 1
    size    = "5G"
    storage = each.value.storage_pool
    mp      = "/mnt/shared"
    volume  = "/mnt/pve/nas-nfs/shared"
    replicate = false
  }
  network {
    name   = "eth0"
    bridge = "vmbr30"
    ip     = each.value.cidr
    hwaddr = each.value.macaddr
    gw     = var.common.gw
    ip6    = "auto"
    mtu    = 1500
    firewall = false
  }

  # Additional service setup
  connection {
    user        = "${data.sops_file.global_secrets.data["k8s.ssh_username"]}"
    type        = "ssh"
    private_key = file("/home/dfroberg/.ssh/id_rsa")
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
    destination = "/root/fstab.txt"
  }
  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "sleep 30",
      "echo '**************************************************** BEGIN ************************************************'",
      "sudo mkdir -p /mnt/backups",
      "sudo cat /root/fstab.txt | sudo tee -a /etc/fstab",
      #"sudo -i sed -Ei 's/^.* (ecdsa-sha2-(nistp384|nistp521)|ssh-(ed25519|dss|rsa))/\1/' /root/.ssh/authorized_keys",
      "echo '*********************************************** UPGRADE & REBOOT *******************************************'",
      "sudo apt upgrade -y && sudo shutdown -r",
      "echo '***************************************************** DONE *************************************************'",
      "exit 0"
    ]
  }
}

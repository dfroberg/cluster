resource "proxmox_lxc" "postgres" {
  for_each    = var.dbs
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
  start       = false
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
  provisioner "file" {
    # Configure LXC
    connection {
      user        = "root"
      type        = "ssh"
      private_key = file("/home/dfroberg/.ssh/id_rsa")
      timeout     = "5m"
      host        = data.sops_file.global_secrets.data["proxmox.pm_host"]
    }
    content     = templatefile("files/configure-lxc.sh.tpl", {
      vmid = each.value.id
      })
    destination = "/tmp/configure-lxc.sh"
  }
  provisioner "remote-exec" {
    # Configure LXC
    connection {
      user        = "root"
      type        = "ssh"
      private_key = file("/home/dfroberg/.ssh/id_rsa")
      timeout     = "5m"
      host        = data.sops_file.global_secrets.data["proxmox.pm_host"]
    }
    # Ensure lxc is stopped, configure it and restart
    inline = [
      "sudo chmod +x /tmp/configure-lxc.sh",
      "/tmp/configure-lxc.sh"
    ]
  }

  # Additional service setup
  connection {
    user        = data.sops_file.global_secrets.data["k8s.ssh_username"]
    type        = "ssh"
    private_key = file("/home/dfroberg/.ssh/id_rsa")
    timeout     = "3m"
    host        = each.value.primary_ip
  }

  # https://www.terraform.io/docs/configuration/functions/templatefile.html
  provisioner "file" {
    content     = templatefile("files/install_postgres.sh.tpl", {
      version = 14
      })
    destination = "/tmp/install_postgres.sh"
  }
  provisioner "file" {
    content     = templatefile("files/setup_postgres_network.sh.tpl", {
      version = 14
      })
    destination = "/tmp/setup_postgres_network.sh"
  }
  provisioner "file" {
    content     = templatefile("files/setup_postgres_tables.sh.tpl", {
      version = 14
      postgres_password = data.sops_file.global_secrets.data["postgres.postgrespw"]
      benji_password = data.sops_file.global_secrets.data["postgres.benjipw"]
      })
    destination = "/tmp/setup_postgres_tables.sh"
  }
  provisioner "file" {
    content     = templatefile("files/fstab.tpl", {
      version = 14
      nas_path = data.sops_file.global_secrets.data["nas.nas_path"]
      nas_ip   = data.sops_file.global_secrets.data["nas.nas_ip"]
      username = data.sops_file.global_secrets.data["nas.user"]
      password = data.sops_file.global_secrets.data["nas.password"]
      })
    destination = "/tmp/fstab.txt"
  }
  provisioner "file" {
    content     = templatefile("files/postgres_dumpall.sh.tpl", {})
    destination = "/root/postgres_dumpall.sh"
  }
  provisioner "file" {
    content     = templatefile("files/postgres_restore.sh.tpl", {})
    destination = "/root/postgres_restore.sh"
  }
  provisioner "file" {
    content     = templatefile("files/add_crontab.sh.tpl", {})
    destination = "/tmp/add_crontab.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "sleep 90",
      "echo '**************************************************** BEGIN ************************************************'",
      "sudo mkdir -p /mnt/backups",
      "sudo cat /tmp/fstab.txt | sudo tee -a /etc/fstab",
      #"sudo -i sed -Ei 's/^.* (ecdsa-sha2-(nistp384|nistp521)|ssh-(ed25519|dss|rsa))/\1/' /root/.ssh/authorized_keys",
      "echo '************************************************** POSTGRES ***********************************************'",
      "sudo chmod +x /tmp/install_postgres.sh",
      "sudo bash /tmp/install_postgres.sh",
      "sudo chmod +x /tmp/setup_postgres_network.sh",
      "sudo bash /tmp/setup_postgres_network.sh",
      "sudo chmod +x /tmp/setup_postgres_tables.sh",
      "sudo bash /tmp/setup_postgres_tables.sh",
      "echo '*************************************************** CRONTAB ***********************************************'",
      "sudo chmod +x /tmp/add_crontab.sh",
      "sudo bash /tmp/add_crontab.sh",
      "sudo chmod +x /root/postgres_dumpall.sh",
      "echo '*************************************************** RESTORE ************************************************'",
      "sudo chmod +x /root/postgres_restore.sh",
      "sudo service postgresql restart",
      "echo '*********************************************** UPGRADE & REBOOT *******************************************'",
      "sudo apt upgrade -y && sudo shutdown -r",
      "echo '***************************************************** DONE *************************************************'",
      "exit 0"
    ]
  }
}
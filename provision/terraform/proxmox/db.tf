resource "proxmox_vm_qemu" "postgres" {
  for_each = var.dbs
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

  # Additional service setup
  connection {
    user        = "${data.sops_file.global_secrets.data["k8s.ssh_username"]}"
    type        = "ssh"
    private_key = file("/home/${data.sops_file.global_secrets.data["k8s.ssh_username"]}/.ssh/id_rsa")
    timeout     = "20m"
    host        = each.value.primary_ip
  }

  # https://www.terraform.io/docs/configuration/functions/templatefile.html
  provisioner "file" {
    content     = templatefile("files/install_postgres.sh.tpl", {
      version = 14
      })
    destination = "/home/dfroberg/install_postgres.sh"
  }
  provisioner "file" {
    content     = templatefile("files/setup_postgres_network.sh.tpl", {
      version = 14
      })
    destination = "/home/dfroberg/setup_postgres_network.sh"
  }
  provisioner "file" {
    content     = templatefile("files/setup_postgres_tables.sh.tpl", {
      version = 14
      postgres_password = data.sops_file.global_secrets.data["postgres.postgrespw"]
      benji_password = data.sops_file.global_secrets.data["postgres.benjipw"]
      })
    destination = "/home/dfroberg/setup_postgres_tables.sh"
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
  provisioner "file" {
    content     = templatefile("files/postgres_dumpall.sh.tpl", {})
    destination = "/home/dfroberg/postgres_dumpall.sh"
  }
  provisioner "file" {
    content     = templatefile("files/postgres_restore.sh.tpl", {})
    destination = "/home/dfroberg/postgres_restore.sh"
  }
  provisioner "file" {
    content     = templatefile("files/add_crontab.sh.tpl", {})
    destination = "/home/dfroberg/add_crontab.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "sleep 90",
      "echo '**************************************************** BEGIN ************************************************'",
      "sudo mkdir -p /mnt/backups",
      "sudo cat /home/dfroberg/fstab.txt | sudo tee -a /etc/fstab",
      "echo '************************************************** POSTGRES ***********************************************'",
      "sudo chmod +x /home/dfroberg/install_postgres.sh",
      "sudo bash /home/dfroberg/install_postgres.sh",
      "sudo chmod +x /home/dfroberg/setup_postgres_network.sh",
      "sudo bash /home/dfroberg/setup_postgres_network.sh",
      "sudo chmod +x /home/dfroberg/setup_postgres_tables.sh",
      "sudo bash /home/dfroberg/setup_postgres_tables.sh",
      "echo '*************************************************** CRONTAB ***********************************************'",
      "sudo chmod +x /home/dfroberg/add_crontab.sh",
      "sudo bash /home/dfroberg/add_crontab.sh",
      "sudo chmod +x /home/dfroberg/postgres_dumpall.sh",
      "echo '*************************************************** RESTORE ************************************************'",
      "sudo chmod +x /home/dfroberg/postgres_restore.sh",
      "sudo service postgresql restart",
      "echo '*********************************************** UPGRADE & REBOOT *******************************************'",
      "sudo apt upgrade -y && sudo shutdown",
      "echo '***************************************************** DONE *************************************************'",
      "exit 0"
    ]
  }
}
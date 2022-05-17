resource "proxmox_vm_qemu" "postgres" {
  for_each = var.dbs
  name        = each.key
  tags        = each.value.tags
  target_node = each.value.target_node
  pool        = "cluster1"
  agent       = 1
  clone       = var.common.clone
  vmid        = each.value.id
  bios        = "ovmf"
  qemu_os     = "l26"
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
  #ipconfig0    = "ip=${each.value.cidr},gw=${var.common.gw}"
  #ipconfig1    = "ip=${each.value.ceph_cidr},gw=${var.common.ceph_gw}"
  #ciuser       = "dfroberg"
  #cipassword   = data.sops_file.secrets.data["k8s.user_password"]
  #searchdomain = var.common.search_domain
  #nameserver   = var.common.nameserver
  #sshkeys      = data.sops_file.secrets.data["k8s.ssh_key"]

  depends_on = [null_resource.cloud_init_config_files,local_file.cloud_init_user_data_file,local_file.cloud_init_meta_data_file,local_file.cloud_init_network_data_file]

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
    ignore_changes  = [
      network,
    ]
  }
  timeouts {
    create = "10m"
    delete = "20m"
  }
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
      #"sudo -i sed -Ei 's/^.* (ecdsa-sha2-(nistp384|nistp521)|ssh-(ed25519|dss|rsa))/\1/' /root/.ssh/authorized_keys",
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
      "sudo apt upgrade -y && sudo shutdown -r",
      "echo '***************************************************** DONE *************************************************'",
      "exit 0"
    ]
  }
}
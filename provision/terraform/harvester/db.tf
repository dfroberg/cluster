resource "harvester_virtualmachine" "kube-db" {
  for_each = var.dbs

  name      = each.key
  namespace = "labcluster"

  description = "k3s db node CIDR: ${each.value.cidr}"
  tags = {
    ssh-user = data.sops_file.global_secrets.data["k8s.ssh_username"]
  }

  cpu    = each.value.vcpus
  memory = each.value.memory

  start        = true
  hostname     = each.key
  machine_type = "q35"

  /* ssh_keys = [
    "labcluster/labsshkey"
  ] */

  network_interface {
    name         = "enp1s0"
    model        = "virtio"
    type         = "bridge"
    network_name = harvester_network.vlan30.id
  }

  network_interface {
    name         = "enp2s0"
    model        = "virtio"
    type         = "bridge"
    network_name = harvester_network.vlan25.id
  }


 
  disk {
    name       = "${each.key}-rootdisk"
    type       = "disk"
    size       = each.value.disk
    bus        = "virtio"
    boot_order = 1

    image       = harvester_image.ubuntu20.id
    auto_delete = true
  }

  cloudinit {
    user_data = templatefile("cloud_config_postgres.tftpl", 
    {
      hostname = each.key
      domain = "cs.aml.ink"
      vm_ssh_user = data.sops_file.global_secrets.data["k8s.ssh_username"]
      vm_ssh_key = data.sops_file.global_secrets.data["k8s.ssh_key"]
      vm_ssh_password = data.sops_file.global_secrets.data["k8s.ssh_password"]
      vm_ssh_root_password = data.sops_file.global_secrets.data["k8s.ssh_root_password"]
    })

    network_data = templatefile("cloud_config_network_v2.tftpl", 
    {
      hostname = each.key
      domain = "cs.aml.ink"
      node_hostname = each.key
      node_ip       = each.value.primary_ip
      node_cidr     = each.value.cidr
      node_gateway  = var.common.gw
      node_dns      = var.common.nameserver
      node_mac_address     = each.value.macaddr
      node_dns_search_domain = var.common.search_domain
      storage_node_cidr     = each.value.ceph_cidr
      storage_node_ip       = each.value.ceph_primary_ip
      storage_node_gateway  = var.common.ceph_gw,
      storage_node_dns      = var.common.ceph_nameserver
      storage_node_mac_address     = each.value.ceph_macaddr
      storage_node_dns_search_domain = var.common.search_domain
    })
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
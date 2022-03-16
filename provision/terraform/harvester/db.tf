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

  ssh_keys = [
    "labcluster/labsshkey"
  ]

  network_interface {
    name         = "nic-1"
    model        = "virtio"
    type         = "bridge"
    network_name = harvester_network.vlan30.id
  }

  network_interface {
    name         = "nic-2"
    model        = "virtio"
    type         = "bridge"
    network_name = harvester_network.vlan25.id
  }


 
  disk {
    name       = "rootdisk"
    type       = "disk"
    size       = each.value.disk
    bus        = "virtio"
    boot_order = 1

    image       = harvester_image.ubuntu20.id
    auto_delete = true
  }

  cloudinit {
    user_data    = <<-EOF
      #cloud-config
      user: ${data.sops_file.global_secrets.data["k8s.ssh_username"]}
      password: ${data.sops_file.global_secrets.data["k8s.ssh_password"]}
      chpasswd:
        expire: false
      sudo: All=(ALL) NOPASSWD:ALL
      ssh_pwauth: true
      # More
      locale: en_US.UTF-8
      timezone: Europe/Stockholm
      local-hostname: ${each.key}
      instance-id: ${each.key}
      package_update: true
      packages:
        - qemu-guest-agent
        - apt-transport-https
        - arptables
        - ca-certificates
        - curl
        - cloud-init
        - ebtables
        - gdisk
        - hdparm
        - htop
        - iputils-ping
        - ipvsadm
        - lvm2
        - net-tools
        - nfs-common
        - nano
        - ntpdate
        - nvme-cli
        - open-iscsi
        - open-vm-tools
        - psmisc
        - smartmontools
        - socat
        - software-properties-common
        - unattended-upgrades
        - unzip
        - lzop 
        - lsscsi 
        - sg3-utils 
        - multipath-tools 
        - scsitools
        - cloud-utils
        - wireguard
        - tmux
      growpart:
        mode: auto
        devices: ['/']
        ignore_growroot_disabled: false
      manage_resolv_conf: true
      resolv_conf:
          nameservers: ['192.168.30.1']
          searchdomains: ['']
      runcmd:
        - - systemctl
          - enable
          - '--now'
          - qemu-guest-agent
      ssh_authorized_keys:
        - >-
          ${data.sops_file.global_secrets.data["k8s.ssh_key"]}
      EOF
    network_data =  <<-EOF
      network:
        version: 2
        ethernets:
          eth0:
            match:
              macaddress: '${each.value.macaddr}'
            wakeonlan: true
            dhcp4: false
            addresses:
              - ${each.value.cidr}
            gateway4: ${var.common.gw}
            nameservers:
              search: ['${var.common.search_domain}']
              addresses: [${var.common.nameserver}]
          eth1:
            match:
              macaddress: '${each.value.ceph_macaddr}'
            wakeonlan: true
            dhcp4: false
            addresses:
              - ${each.value.ceph_cidr}
            gateway4: ${var.common.ceph_gw}
            nameservers:
              search: ['${var.common.search_domain}']
              addresses: [${var.common.ceph_nameserver}]
            mtu: 9000
      # More
      locale: en_US.UTF-8
      timezone: Europe/Stockholm
      local-hostname: ${each.key}
      instance-id: ${each.key}
      EOF
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
      username = data.sops_file.global_secrets.data["nas.username"]
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
      "sudo chmod +x /home/dfroberg/install_postgres.sh",
      "sudo bash /home/dfroberg/install_postgres.sh",
      "sudo chmod +x /home/dfroberg/setup_postgres_network.sh",
      "sudo bash /home/dfroberg/setup_postgres_network.sh",
      "sudo chmod +x /home/dfroberg/setup_postgres_tables.sh",
      "sudo bash /home/dfroberg/setup_postgres_tables.sh",
      "sudo chmod +x /home/dfroberg/add_crontab.sh",
      "sudo bash /home/dfroberg/add_crontab.sh",
      "sudo chmod +x /home/dfroberg/postgres_dumpall.sh",
      "sudo chmod +x /home/dfroberg/postgres_restore.sh",
      "sudo apt upgrade -y",
      "sudo service postgres restart",
      "sudo mkdir -p /mnt/backups",
      "sudo cat /home/dfroberg/fstab.txt >> /etc/fstab",
      "sudo shutdown -r NOW"
    ]
  }
}
resource "harvester_virtualmachine" "kube-storage" {
  for_each = var.storage

  name      = each.key
  namespace = "labcluster"

  description = "k3s storage node CIDR: ${each.value.cidr}"
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

  disk {
    name        = "emptydisk"
    type        = "disk"
    size        = each.value.storage_disk
    bus         = "virtio"
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
}
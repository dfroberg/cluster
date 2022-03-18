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

  disk {
    name        = "${each.key}-storagedisk"
    type        = "disk"
    access_mode = "ReadWriteOnce"
    size        = each.value.storage_disk
    bus         = "virtio"
    auto_delete = true
  }

  cloudinit {
    user_data = templatefile("cloud_config.tftpl", {
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
}
/* Null resource that generates a cloud-config file per vm */
# Masters
data "template_file" "user_data" {
  for_each = merge(var.masters,var.workers,var.storage,var.dbs)

  template = file("${path.module}/files/user-data.yaml")
  vars = {
    username    = var.common.username
    ssh_public_key   = data.sops_file.secrets.data["k8s.ssh_key"]
    node_hostname = "${each.key}"
    node_fqdn     = "${each.key}.${var.common.node_fqdn}"
  }
}
data template_file "meta_data" {
  for_each = merge(var.masters,var.workers,var.storage,var.dbs)
  template = file("${path.module}/files/meta-data.yaml")
  vars = {
    hostname    = "${each.key}"
  }
}
data template_file "network_data" {
  for_each = merge(var.masters,var.workers,var.storage,var.dbs)
  template = file("${path.module}/files/network-data.yaml")
  vars = {
    hostname = each.key
    domain = "cs.aml.ink"
    node_search_domain = var.common.search_domain
    node_hostname = each.key
    node_ip       = each.value.cidr
    node_gateway  = var.common.gw
    node_dns      = var.common.nameserver
    node_mac_address     = each.value.macaddr
    node_dns_search_domain = var.common.search_domain
    storage_node_ip       = each.value.ceph_cidr
    storage_node_gateway  = var.common.ceph_gw,
    storage_node_dns      = var.common.ceph_nameserver
    storage_node_mac_address     = each.value.ceph_macaddr
    storage_node_dns_search_domain = var.common.search_domain
  }
}
resource "local_file" "cloud_init_user_data_file" {
  for_each = merge(var.masters,var.workers,var.storage,var.dbs)
  content  = data.template_file.user_data[each.key].rendered
  filename = "${path.module}/files/vm-${each.value.id}-user-data.yaml"
}
resource "local_file" "cloud_init_meta_data_file" {
  for_each = merge(var.masters,var.workers,var.storage,var.dbs)
  content  = data.template_file.meta_data[each.key].rendered
  filename = "${path.module}/files/vm-${each.value.id}-meta-data.yaml"
}
resource "local_file" "cloud_init_network_data_file" {
  for_each = merge(var.masters,var.workers,var.storage,var.dbs)
  content  = data.template_file.network_data[each.key].rendered
  filename = "${path.module}/files/vm-${each.value.id}-network-data.yaml"
}
resource "null_resource" "cloud_init_config_files" {
  for_each = merge(var.masters,var.workers,var.storage,var.dbs)
  connection {
    type     = "ssh"
    user     = data.sops_file.secrets.data["proxmox.user"]
    host     = data.sops_file.secrets.data["proxmox.pm_host"]
    port     = 22
    private_key = "${file("/home/dfroberg/.ssh/id_rsa")}"
    agent = false
    timeout = "20s"
  }

  provisioner "file" {
    source      = local_file.cloud_init_user_data_file[each.key].filename
    destination = "/mnt/pve/nas-nfs/snippets/vm-${each.value.id}-user-data.yaml"
  }
  provisioner "file" {
    source      = local_file.cloud_init_meta_data_file[each.key].filename
    destination = "/mnt/pve/nas-nfs/snippets/vm-${each.value.id}-meta-data.yaml"
  }
  provisioner "file" {
    source      = local_file.cloud_init_network_data_file[each.key].filename
    destination = "/mnt/pve/nas-nfs/snippets/vm-${each.value.id}-network-data.yaml"
  }
}

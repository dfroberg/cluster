/* Null resource that generates a cloud-config file per vm */
# Masters
data "template_file" "cps-user_data" {
  for_each = merge(var.cps)

  template = file("${path.module}/files/cps/user-data.yaml")
  vars = {
    username    = var.common.username
    node_hostname = "${each.key}"
    node_fqdn     = "${each.key}.${var.common.node_fqdn}"
    hostname = each.key
    domain = "cs.aml.ink"
    node_search_domain = var.common.search_domain
    node_hostname = each.key
    node_ip       = each.value.primary_ip
    node_cidr       = each.value.cidr
    node_gateway  = var.common.gw
    node_dns      = var.common.nameserver
    node_mac_address     = each.value.macaddr
    node_dns_search_domain = var.common.search_domain
    SECRET_NEXUS_USERNAME = data.sops_file.secrets.data["talos.SECRET_NEXUS_USERNAME"]
    SECRET_NEXUS_PASSWORD = data.sops_file.secrets.data["talos.SECRET_NEXUS_PASSWORD"]
  }
}
data template_file "cps-meta_data" {
  for_each = merge(var.cps)
  template = file("${path.module}/files/cps/meta-data.yaml")
  vars = {
    hostname    = "${each.key}"
  }
}
data template_file "cps-network_data" {
  for_each = merge(var.cps)
  template = file("${path.module}/files/cps/network-data.yaml")
  vars = {
    hostname = each.key
    domain = "cs.aml.ink"
    node_search_domain = var.common.search_domain
    node_hostname = each.key
    node_ip       = each.value.primary_ip
    node_gateway  = var.common.gw
    node_dns      = var.common.nameserver
    node_mac_address     = each.value.macaddr
    node_dns_search_domain = var.common.search_domain
  }
}
resource "local_file" "cloud_init_cps_user_data_file" {
  for_each = merge(var.cps)
  content  = data.template_file.cps-user_data[each.key].rendered
  filename = "${path.module}/files/cps/vm-${each.value.id}-user-data.yaml"
}
resource "local_file" "cloud_init_cps_meta_data_file" {
  for_each = merge(var.cps)
  content  = data.template_file.cps-meta_data[each.key].rendered
  filename = "${path.module}/files/cps/vm-${each.value.id}-meta-data.yaml"
}
resource "local_file" "cloud_init_cps_network_data_file" {
  for_each = merge(var.cps)
  content  = data.template_file.cps-network_data[each.key].rendered
  filename = "${path.module}/files/cps/vm-${each.value.id}-network-data.yaml"
}
resource "null_resource" "cloud_init_cps_config_files" {
  for_each = merge(var.cps)
  connection {
    type     = "ssh"
    user     = data.sops_file.secrets.data["proxmox.user"]
    host     = data.sops_file.secrets.data["proxmox.pm_host"]
    port     = 22
    private_key = "${file("/home/dfroberg/.ssh/id_rsa")}"
    agent = false
    timeout = "20s"
  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = data.sops_file.secrets.data["proxmox.user"]
      host     = data.sops_file.secrets.data["proxmox.pm_host"]
      port     = 22
      private_key = "${file("/home/dfroberg/.ssh/id_rsa")}"
      agent = false
      timeout = "20s"
    }
    inline = [
      "mkdir -p /mnt/pve/nas-nfs/snippets/talos/${each.value.id}/"
    ]
  }

  provisioner "file" {
    source      = local_file.cloud_init_cps_user_data_file[each.key].filename
    destination = "/mnt/pve/nas-nfs/snippets/vm-${each.value.id}-user-data.yaml"
  }
  provisioner "file" {
    source      = local_file.cloud_init_cps_user_data_file[each.key].filename
    destination = "/mnt/pve/nas-nfs/snippets/talos/${each.value.id}/user-data.yaml"
  }
  provisioner "file" {
    source      = local_file.cloud_init_cps_network_data_file[each.key].filename
    destination = "/mnt/pve/nas-nfs/snippets/vm-${each.value.id}-network-data.yaml"
  }
  provisioner "file" {
    source      = local_file.cloud_init_cps_network_data_file[each.key].filename
    destination = "/mnt/pve/nas-nfs/snippets/talos/${each.value.id}/network-data.yaml"
  }
  provisioner "file" {
    source      = local_file.cloud_init_cps_meta_data_file[each.key].filename
    destination = "/mnt/pve/nas-nfs/snippets/vm-${each.value.id}-meta-data.yaml"
  }
}

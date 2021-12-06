resource "esxi_guest" "kube-master" {
  for_each = var.masters

  guest_name      = each.key

  clone_from_vm      = "ubuntu-20.04-server-cloudimg-amd64"
  power              = "on"
  memsize         = each.value.memory
  numvcpus        = each.value.vcpus
  disk_store      = each.value.storage_pool
  boot_disk_type = "thin"
  boot_disk_size  = each.value.disk
  
   
  guestinfo = {
    "metadata" = base64encode(templatefile("${path.module}/templates/metadata.yml.tpl", {
      node_hostname = each.key,
      node_ip       = each.value.cidr,
      node_gateway  = each.value.gw,
      node_dns      = var.common.nameserver,
      node_dns_search_domain = var.common.search_domain
      storage_node_ip       = each.value.ceph_cidr,
      storage_node_gateway  = var.common.ceph_gw,
      storage_node_dns      = var.common.ceph_nameserver,
      storage_node_dns_search_domain = var.common.search_domain
    }))

    "metadata.encoding" = "base64"

    "userdata" = base64encode(templatefile("${path.module}/templates/userdata.yml.tpl", {
        vm_ssh_user = var.common.username,
        vm_ssh_key = data.sops_file.secrets.data["k8s.ssh_key"]
        vm_ssh_password = data.sops_file.secrets.data["k8s.ssh_password"]
    }))

    "userdata.encoding" = "base64"
  }

  network_interfaces {
    nic_type = "vmxnet3"
    virtual_network = "k3s"
    mac_address     = each.value.macaddr
  }
  network_interfaces {
    nic_type = "vmxnet3"
    virtual_network = "iscsi"
    mac_address     = each.value.ceph_macaddr
  }

  # bootdisk     = "pvscsi"
  # scsihw       = "virtio-scsi-pci"
  # os_type      = "cloud-init"
  #ipconfig0    = "ip=${each.value.cidr},gw=${each.value.gw}"
  #ipconfig1    = "ip=${each.value.ceph_cidr}"
  #ciuser       = "dfroberg"
  #cipassword   = data.sops_file.secrets.data["k8s.user_password"]

}

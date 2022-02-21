resource "xenorchestra_cloud_config" "db_user_config" {
  for_each = var.dbs
  name = "${each.key} cloud config user config"
  # Template the cloudinit if needed
  template = templatefile("cloud_config.tftpl", {
    hostname = each.key
    domain = "cs.aml.ink"
    vm_ssh_user = data.sops_file.global_secrets.data["k8s.ssh_username"]
    vm_ssh_key = data.sops_file.global_secrets.data["k8s.ssh_key"]
    vm_ssh_password = data.sops_file.global_secrets.data["k8s.ssh_password"]
    vm_ssh_root_password = data.sops_file.global_secrets.data["k8s.ssh_root_password"]
  })
}
resource "xenorchestra_cloud_config" "db_network_config" {
  for_each = var.dbs
  name = "${each.key} cloud config network config"
  # Template the cloudinit if needed
  template = templatefile("cloud_config_network_v1.tftpl", {
    hostname = each.key
    domain = "cs.aml.ink"
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
  })
}

resource "xenorchestra_vm" "kube-db" {
  for_each = var.dbs

  # Node Description
  memory_max = each.value.memory
  cpus  = each.value.vcpus
  auto_poweron = true
  cloud_config = xenorchestra_cloud_config.db_user_config[each.key].template
  cloud_network_config = xenorchestra_cloud_config.db_network_config[each.key].template
  name_label = each.key
  name_description = "k3s db node CIDR: ${each.value.cidr}"
  template = data.xenorchestra_template.vm_template.id

  # Prefer to run the VM on the primary pool instance
  affinity_host = data.xenorchestra_pool.pool.master

  network {
    network_id = data.xenorchestra_network.k3s_net.id
    mac_address = each.value.macaddr
  }

  network {
    network_id = data.xenorchestra_network.storage_net.id
    mac_address = each.value.ceph_macaddr
  }

  disk {
    sr_id = data.xenorchestra_sr.sr.id
    name_label = "${each.key} root"
    size = each.value.disk
  }

  tags = [
    "Ubuntu",
    "Focal",
    "k3s",
    "db"
  ]

  // Override the default create timeout from 5 mins to 20.
  timeouts {
    create = "30m"
  }

  connection {
    user        = "dfroberg"
    type        = "ssh"
    private_key = file("/home/dfroberg/.ssh/id_rsa")
    timeout     = "2m"
    host        = each.value.primary_ip
  }

  # https://www.terraform.io/docs/configuration/functions/templatefile.html
  provisioner "file" {
    content     = templatefile("files/setup_postgres.sh.tpl", {})
    destination = "/tmp/setup_postgres.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -",
      "echo \"deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main\" |sudo tee  /etc/apt/sources.list.d/pgdg.list",
      "sudo apt-get update",
      "sudo apt-get -y install postgresql-12 postgresql-client-12",
      "sudo -u postgres psql -c \"alter user postgres with password '${data.sops_file.global_secrets.data["postgres.postgrespw"]}';\"",
      "sudo -u postgres psql -c \"CREATE DATABASE cluster;\"",
      "sudo -u postgres psql -c \"CREATE USER cluster WITH ENCRYPTED PASSWORD '${data.sops_file.global_secrets.data["postgres.postgrespw"]}';\"",
      "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE cluster to cluster;\"",
      "sudo -u postgres psql -c \"CREATE DATABASE benji;\"",
      "sudo -u postgres psql -c \"CREATE USER benji WITH ENCRYPTED PASSWORD '${data.sops_file.global_secrets.data["postgres.benjipw"]}';\"",
      "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE benji to benji;\"",
      "sudo -u postgres psql -c \"CREATE DATABASE authentik;\"",
      "sudo -u postgres psql -c \"CREATE USER authentik WITH ENCRYPTED PASSWORD '${data.sops_file.global_secrets.data["postgres.postgrespw"]}';\"",
      "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE authentik to authentik;\"",
      "sudo -u postgres psql -c \"CREATE DATABASE vikunja;\"",
      "sudo -u postgres psql -c \"CREATE USER vikunja WITH ENCRYPTED PASSWORD '${data.sops_file.global_secrets.data["postgres.postgrespw"]}';\"",
      "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE vikunja to vikunja;\"",
      "sudo -u postgres psql -c \"CREATE DATABASE healthchecks;\"",
      "sudo -u postgres psql -c \"CREATE USER healthchecks WITH ENCRYPTED PASSWORD '${data.sops_file.global_secrets.data["postgres.postgrespw"]}';\"",
      "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE healthchecks to healthchecks;\"",
      "sudo -u postgres psql -c \"CREATE DATABASE recipes;\"",
      "sudo -u postgres psql -c \"CREATE USER recipes WITH ENCRYPTED PASSWORD '${data.sops_file.global_secrets.data["postgres.postgrespw"]}';\"",
      "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE recipes to recipes;\"",
      "sudo -u postgres psql -c \"CREATE DATABASE joplin;\"",
      "sudo -u postgres psql -c \"CREATE USER joplin WITH ENCRYPTED PASSWORD '${data.sops_file.global_secrets.data["postgres.postgrespw"]}';\"",
      "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE joplin to joplin;\"",
      "sudo -u postgres psql -c \"CREATE DATABASE authelia;\"",
      "sudo -u postgres psql -c \"CREATE USER authelia WITH ENCRYPTED PASSWORD '${data.sops_file.global_secrets.data["postgres.postgrespw"]}';\"",
      "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE authelia to authelia;\"",
      "sudo -u postgres psql -c \"CREATE DATABASE vaultwarden;\"",
      "sudo -u postgres psql -c \"CREATE USER vaultwarden WITH ENCRYPTED PASSWORD '${data.sops_file.global_secrets.data["postgres.postgrespw"]}';\"",
      "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE vaultwarden to vaultwarden;\"",
      "sudo chmod +x /tmp/setup_postgres.sh",
      "sudo bash /tmp/setup_postgres.sh",
      "echo done"
    ]
  }

}
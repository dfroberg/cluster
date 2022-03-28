# Instruct terraform to download the provider on `terraform init`
terraform {
  required_providers {
    harvester = {
      source = "harvester/harvester"
      version = "0.3.1"
    }
    sops = {
      source = "carlpett/sops"
      version = "0.6.3"
    }
  }
}
data "sops_file" "global_secrets" {
  source_file = "secrets.sops.yaml"
}

provider "sops" {}

# Configure the Harvester Provider
provider "harvester" {
  # i.e. /home/youruser/.kube/local.yaml
  kubeconfig = data.sops_file.global_secrets.data["harvester.kubeconfig"]
}

# Configure Root Resources
resource "harvester_ssh_key" "labsshkey" {
  name      = "labsshkey"
  namespace = "labcluster"

  public_key = "${data.sops_file.global_secrets.data["k8s.ssh_key"]}"
}

resource "harvester_network" "vlan30" {
  name      = "vlan30"
  namespace = "labcluster"

  vlan_id = "30"

  /* route_mode    = "manual"
  route_cidr    = "192.168.30.1/24"
  route_gateway = "192.168.30.1" */
}

resource "harvester_network" "vlan25" {

  name      = "vlan25"
  namespace = "labcluster"

  vlan_id = "25"

  /* route_mode    = "manual"
  route_cidr    = "192.168.25.1/24"
  route_gateway = "192.168.25.1" */
}

resource "harvester_image" "ubuntu20" {
  name      = "ubuntu20"
  namespace = "labcluster"

  display_name = "ubuntu20"
  source_type  = "download"
  url          = "http://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64.iso"
}
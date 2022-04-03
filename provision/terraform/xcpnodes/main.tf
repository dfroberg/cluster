# Instruct terraform to download the provider on `terraform init`
terraform {
  required_providers {
    xenorchestra = {
      source = "terra-farm/xenorchestra"
      version = "~> 0.23.0"
    }
    sops = {
      source = "carlpett/sops"
      version = "0.7.0"
    }
  }
}
data "sops_file" "global_secrets" {
  source_file = "secrets.sops.yaml"
}

provider "sops" {}

# Configure the XenServer Provider
provider "xenorchestra" {
  # Must be ws or wss
  url      = "wss://192.168.3.103" # Or set XOA_URL environment variable
  username = data.sops_file.global_secrets.data["xenorchestra.username"]
  password = data.sops_file.global_secrets.data["xenorchestra.password"]
  insecure = "true"
}

data "xenorchestra_pool" "pool" {
    name_label = "xcp-ng-01"
}

data "xenorchestra_template" "vm_template" {
  name_label = "Ubuntu 20.04 Cloud-Init 71"
}

data "xenorchestra_sr" "sr" {
  name_label = "ld2"
  pool_id = data.xenorchestra_pool.pool.id
}

data "xenorchestra_network" "k3s_net" {
  name_label = "k3s"
  pool_id = data.xenorchestra_pool.pool.id
}

data "xenorchestra_network" "storage_net" {
  name_label = "storage"
  pool_id = data.xenorchestra_pool.pool.id
}

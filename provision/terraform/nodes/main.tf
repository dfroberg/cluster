terraform {
  required_version = ">= 0.13.0"

  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "2.9.0"
    }
    minio = {
      source = "refaktory/minio"
      version = "0.1.0"
    }
    sops = {
      source = "carlpett/sops"
      version = "0.6.3"
    }
  }
}

data "sops_file" "global_secrets" {
  source_file = "secret.sops.yaml"
}

provider "proxmox" {
  pm_tls_insecure     = true
  pm_api_url          = "https://192.168.3.100:8006/api2/json"
  pm_parallel         = 4
  pm_api_token_id     = data.sops_file.global_secrets.data["proxmox.pm_api_token_id"]
  pm_api_token_secret = data.sops_file.global_secrets.data["proxmox.pm_api_token_secret"]
}

provider "sops" {}

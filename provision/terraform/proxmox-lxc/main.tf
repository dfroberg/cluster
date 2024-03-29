terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.11"
    }
    sops = {
      source = "carlpett/sops"
      version = "0.7.1"
    }
  }
}

data "sops_file" "global_secrets" {
  source_file = "secret.sops.yaml"
}

provider "proxmox" {
  pm_tls_insecure     = true
  pm_api_url          = "https://192.168.3.100:8006/api2/json"
  pm_parallel         = 1
  #pm_api_token_id     = data.sops_file.global_secrets.data["proxmox.pm_api_token_id"]
  #pm_api_token_secret = data.sops_file.global_secrets.data["proxmox.pm_api_token_secret"]
  pm_user             = data.sops_file.global_secrets.data["proxmox.pm_user"]
  pm_password         = data.sops_file.global_secrets.data["proxmox.pm_password"]
  pm_log_enable       = true
  pm_log_file         = "terraform-plugin-proxmox.log"
  #pm_debug            = true
  pm_log_levels       = {
    _default          = "debug"
    _capturelog       = ""
  }
}

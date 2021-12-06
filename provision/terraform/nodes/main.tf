terraform {
  required_version = ">= 0.13.0"

  required_providers {
    esxi = {
      source = "registry.terraform.io/josenk/esxi"
      #
      # For more information, see the provider source documentation:
      # https://github.com/josenk/terraform-provider-esxi
      # https://registry.terraform.io/providers/josenk/esxi
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
provider "esxi" {
  esxi_hostname      = data.sops_file.global_secrets.data["esxi.esxi_host"]
  esxi_hostport      = "22"
  esxi_hostssl       = "443"
  esxi_username      = data.sops_file.global_secrets.data["esxi.esxi_user"]
  esxi_password      = data.sops_file.global_secrets.data["esxi.esxi_password"]
}

provider "sops" {}

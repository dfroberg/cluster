# Instruct terraform to download the provider on `terraform init`
terraform {
  required_providers {
    xenorchestra = {
      source = "terra-farm/xenorchestra"
      version = "~> 0.3.0"
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
  url      = "ws://192.168.3.101" # Or set XOA_URL environment variable
  username = data.sops_file.global_secrets.data["xenorchestra.username"]
  password = data.sops_file.global_secrets.data["xenorchestra.password"]
  insecure = true 
}

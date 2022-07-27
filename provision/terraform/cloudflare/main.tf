terraform {

  backend "remote" {
    organization = "dfroberg"
    workspaces {
      name = "lab-cloudflare-tld"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.18.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.0.1"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.1"
    }
  }
}

data "sops_file" "cloudflare_secrets" {
  source_file = "secret.sops.yaml"
}

provider "cloudflare" {
  email   = data.sops_file.cloudflare_secrets.data["cloudflare_email"]
  api_key = data.sops_file.cloudflare_secrets.data["cloudflare_apikey"]
}

data "cloudflare_zones" "domain" {
  filter {
    name = data.sops_file.cloudflare_secrets.data["cloudflare_domain"]
  }
}

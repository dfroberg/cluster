terraform {

  required_providers {
    minio = {
      source = "refaktory/minio"
      version = "0.1.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.6.3"
    }
  }
}

data "sops_file" "minio_secrets" {
  source_file = "secret.sops.yaml"
}

provider "minio" {
  endpoint = data.sops_file.minio_secrets.data["minio_endpoint"]
  access_key = data.sops_file.minio_secrets.data["minio_access_key"]
  secret_key = data.sops_file.minio_secrets.data["minio_secret_key"]
  ssl = true
}

resource "minio_bucket" "bucket" {
  name = "bucket"
}
resource "minio_bucket" "bucket" {
  name = "velero"
}

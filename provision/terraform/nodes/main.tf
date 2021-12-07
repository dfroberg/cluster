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

# Global resources
resource "esxi_resource_pool" "High" {
  resource_pool_name  = "High"
  cpu_min             = 10000
  cpu_min_expandable  = true
  cpu_max             = 30000
  cpu_shares          = 8000
  mem_min             = 30720
  mem_min_expandable  = true
  mem_max             = 30720
  mem_shares          = 327680
}
resource "esxi_resource_pool" "Normal" {
  resource_pool_name  = "Normal"
  cpu_min             = 10000
  cpu_min_expandable  = true
  cpu_max             = 30000
  cpu_shares          = 4000
  mem_min             = 16384
  mem_min_expandable  = true
  mem_max             = 16384
  mem_shares          = 163840
}

# esxi_virtual_disk.storage01_disk1:
resource "esxi_virtual_disk" "storage01_disk1" {
    virtual_disk_name  = "storage01_disk1.vmdk"
    virtual_disk_dir = "storage01"
    virtual_disk_disk_store = "vmdata"
    virtual_disk_size = 50
}

# esxi_virtual_disk.storage02_disk1:
resource "esxi_virtual_disk" "storage02_disk1" {
    virtual_disk_name  = "storage02_disk1.vmdk"
    virtual_disk_dir = "storage02"
    virtual_disk_disk_store = "vmdata"
    virtual_disk_size = 50
}

# esxi_virtual_disk.storage03_disk1:
resource "esxi_virtual_disk" "storage03_disk1" {
    virtual_disk_name  = "storage03_disk1.vmdk"
    virtual_disk_dir = "storage03"
    virtual_disk_disk_store = "vmdata"
    virtual_disk_size = 50
}
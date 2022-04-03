terraform {
  required_version = ">= 0.13.0"

  required_providers {
    hyperv = {
      version = "1.0.3"
      source = "registry.terraform.io/taliesins/hyperv"
    }
    sops = {
      source = "carlpett/sops"
      version = "0.7.0"
    }
  }
}

data "sops_file" "global_secrets" {
  source_file = "secret.sops.yaml"
}

# Configure HyperV
provider "hyperv" {
  user            = data.sops_file.global_secrets.data["hyperv.host_user"]
  password        = data.sops_file.global_secrets.data["hyperv.host_password"]
  host            = data.sops_file.global_secrets.data["hyperv.host_host"]
  port            = 5986
  https           = true
  insecure        = true
  use_ntlm        = true
  tls_server_name = ""
  cacert_path     = ""
  cert_path       = ""
  key_path        = ""
  timeout         = "60s"
}

# Single node test

resource "hyperv_network_switch" "external_network_switch" {
  name = "External"
  switch_type = "External"
  allow_management_os = true
  net_adapter_names = ["Ethernet"]
}

resource "hyperv_vhd" "worker04_vhd" {
  path = "D:\\HyperV-VMs\\Virtual Hard Disks\\worker04.vhdx" #Needs to be absolute path
  size = 6*10737418240 #6*10GB
}

resource "hyperv_machine_instance" "worker04" {
  name = "worker04"
  generation = 1
  processor_count = 8
  static_memory = true
  memory_startup_bytes = 536870912 #512MB
  wait_for_state_timeout = 10
  wait_for_ips_timeout = 10

  vm_processor {
    expose_virtualization_extensions = true
  }

  network_adaptors {
      name = "vlan30"
      vlan_id = 30
      static_mac_address = "68:b5:99:b3:da:0d"
      switch_name = hyperv_network_switch.external_network_switch.name
      wait_for_ips = false
  }
  network_adaptors {
      name = "vlan25"
      vlan_id = 25
      static_mac_address = "68:b5:99:b3:db:0d"
      switch_name = hyperv_network_switch.external_network_switch.name
      wait_for_ips = false
  }
  hard_disk_drives {
    controller_type = "Scsi"
    path = hyperv_vhd.worker04_vhd.path
    controller_number = 0
    controller_location = 0
  }

  dvd_drives {
    controller_number = 0
    controller_location = 1
    #path = "ubuntu.iso"
  }
}


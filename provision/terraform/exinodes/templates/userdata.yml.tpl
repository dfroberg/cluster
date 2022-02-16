#cloud-config
manage_etc_hosts: true
user: ${vm_ssh_user}
password: ${vm_ssh_password}
ssh_authorized_keys:
  - ${vm_ssh_key}
sudo: All=(ALL) NOPASSWD:ALL
chpasswd:
  expire: False
users:
  - default
package_upgrade: true

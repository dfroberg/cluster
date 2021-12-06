#cloud-config
users:
  - name: ${vm_ssh_user}
    ssh-authorized-keys:
      - ${vm_ssh_key}
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_import_id:
      - gh: ${vm_ssh_user}
    passwd: ${vm_ssh_password}
    shell: /bin/bash
  - name: root
    ssh-authorized-keys:
      - ${vm_ssh_key}
    ssh_import_id:
      - gh: ${vm_ssh_user}
    passwd: ${vm_ssh_password}
    shell: /bin/bash

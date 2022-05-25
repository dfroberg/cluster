# Preparing Proxmox for use with Terraform
The particular privileges required may change but here is a suitable starting point rather than using cluster-wide Administrator rights

Log into the Proxmox cluster or host using ssh (or mimic these in the GUI) then:

* Create a new role for the future terraform user.
* Create the user "terraform-prov@pve"
* Add the TERRAFORM-PROV role to the terraform-prov user
~~~sh
pveum role add TerraformProv -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Monitor VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit"

pveum user add terraform-prov@pve --password <password>
pveum aclmod / -user terraform-prov@pve -role TerraformProv
~~~
The provider also supports using an API key rather than a password, see below for details.

pveum user token add terraform-prov@pve terraform-token --privsep=0

After the role is in use, if there is a need to modify the privileges, simply issue the command showed, adding or removing privileges as needed.
~~~sh
pveum role modify TerraformProv -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Monitor VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit Datastore.Allocate Pool.Allocate""
~~~
### Creating the connection via username and API token
~~~sh
export PM_API_TOKEN_ID="terraform-prov@pve!mytoken"
export PM_API_TOKEN_SECRET="afcd8f45-acc1-4d0f-bb12-a70b0777ec11"
~~~
~~~yaml
provider "proxmox" {
    pm_api_url = "https://proxmox-server01.example.com:8006/api2/json"
}
~~~
# Peparing Ubuntu cloudinit image for Proxmox

### Install libguestfs-tools on Proxmox server.
~~~sh
sudo apt install libguestfs-tools`
~~~
## Talos 1.0.5
~~~sh
export VM_NAME="talos-1-0-5-amd64"
export VM_IMG="talos-amd64.iso"
~~~
### Talos ISO
~~~sh
curl -s https://github.com/siderolabs/talos/releases/download/v1.0.5/$VM_IMG -L -o _out/talos-amd64.iso
~~~

## Common steps
~~~sh
export STORAGE_POOL="local"
export VM_ID="10001"
export VM_ROOTPW="yourpassword"
~~~

### Create Proxmox VM image from Ubuntu Cloud Image.
~~~sh
qm create $VM_ID --bios ovmf --ostype l26 --numa 1 --cpu cputype=host --memory 2048 --net0 virtio,bridge=vmbr30,firewall=0 --net1 virtio,bridge=vmbr25,firewall=0 --description "Node Template" --onboot no

qm importdisk $VM_ID $VM_IMG $STORAGE_POOL

qm set $VM_ID --scsihw virtio-scsi-pci --virtio0 $STORAGE_POOL:$VM_ID/vm-$VM_ID-disk-0.raw
qm set $VM_ID --efidisk0 $STORAGE_POOL:0,pre-enrolled-keys=1
qm set $VM_ID --agent enabled=1,fstrim_cloned_disks=1
qm set $VM_ID --name $VM_NAME
~~~

### Create Cloud-Init Disk and configure boot.
~~~sh
# This REALLY need to be scsi1 instead of ide2 otherwise 
# it wont be pocked up on first boot
qm set $VM_ID --scsi1 $STORAGE_POOL:cloudinit

qm set $VM_ID --boot c --bootdisk virtio0
qm set $VM_ID --serial0 socket --vga serial0

qm template $VM_ID
~~~
## Cleanup
~~~sh
rm $VM_IMG
~~~

## Everything in One Go
~~~sh
export VM_NAME="talos-1-0-5-amd64"
export VM_IMG="talos-amd64.iso"
export STORAGE_POOL="local"
export STORAGE_POOL_CI="nas-nfs"
export VM_ID="10001"

rm $VM_IMG
curl -s https://github.com/siderolabs/talos/releases/download/v1.0.5/$VM_IMG -L -o $VM_IMG
qm destroy $VM_ID
qm create $VM_ID --bios ovmf --ostype l26 --numa 1 --cpu cputype=host --memory 2048 --net0 virtio,bridge=vmbr30,firewall=0 --description "Talos Node Template" --onboot no
qm importdisk $VM_ID $VM_IMG $STORAGE_POOL
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $STORAGE_POOL:$VM_ID/vm-$VM_ID-disk-0.raw
#qm set $VM_ID --efidisk0 $STORAGE_POOL:0,pre-enrolled-keys=1
qm set $VM_ID --agent enabled=1,fstrim_cloned_disks=1
qm set $VM_ID --name $VM_NAME
#qm set $VM_ID --scsi1 $STORAGE_POOL_CI:cloudinit
qm set $VM_ID --boot c --bootdisk scsi0
qm set $VM_ID --serial0 socket --vga serial0
qm template $VM_ID
rm $VM_IMG
~~~
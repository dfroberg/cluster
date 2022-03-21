# Preparing Proxmox for use with Terraform
The particular privileges required may change but here is a suitable starting point rather than using cluster-wide Administrator rights

Log into the Proxmox cluster or host using ssh (or mimic these in the GUI) then:

* Create a new role for the future terraform user.
* Create the user "terraform-prov@pve"
* Add the TERRAFORM-PROV role to the terraform-prov user
~~~
pveum role add TerraformProv -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Monitor VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit"

pveum user add terraform-prov@pve --password <password>
pveum aclmod / -user terraform-prov@pve -role TerraformProv
~~~
The provider also supports using an API key rather than a password, see below for details.

After the role is in use, if there is a need to modify the privileges, simply issue the command showed, adding or removing priviledges as needed.
~~~
pveum role modify TerraformProv -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Monitor VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit Datastore.Allocate Pool.Allocate""
~~~
### Creating the connection via username and API token
~~~
export PM_API_TOKEN_ID="terraform-prov@pve!mytoken"
export PM_API_TOKEN_SECRET="afcd8f45-acc1-4d0f-bb12-a70b0777ec11"
~~~
~~~
provider "proxmox" {
    pm_api_url = "https://proxmox-server01.example.com:8006/api2/json"
}
~~~
# Peparing Ubuntu cloudinit image for Proxmox

### Download Ubuntu 20.04 cloudimg
`wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img`

### Install libguestfs-tools on Proxmox server.
`apt-get install libguestfs-tools`

### Install qemu-guest-agent on Ubuntu image.
`virt-customize -a focal-server-cloudimg-amd64.img --install qemu-guest-agent`

### Enable password authentication in the template. Obviously, not recommended for except for testing.
`virt-customize -a focal-server-cloudimg-amd64.img --run-command "sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config"`

### Set environment variables. Change these as necessary.
```sh
export STORAGE_POOL="nas-nfs"
export VM_ID="10000"
export VM_NAME="ubuntu-20-04-cloudimg"
```

### Create Proxmox VM image from Ubuntu Cloud Image.
```sh
qm create $VM_ID --memory 2048 --net0 virtio,bridge=vmbr30
qm importdisk $VM_ID focal-server-cloudimg-amd64.img $STORAGE_POOL
qm set $VM_ID --scsihw virtio-scsi-pci --scsi0 $STORAGE_POOL:$VM_ID/vm-$VM_ID-disk-0.raw
qm set $VM_ID --agent enabled=1,fstrim_cloned_disks=1
qm set $VM_ID --name $VM_NAME
```

### Create Cloud-Init Disk and configure boot.
```sh
qm set $VM_ID --ide2 $STORAGE_POOL:cloudinit
qm set $VM_ID --boot c --bootdisk scsi0
qm set $VM_ID --serial0 socket --vga serial0

qm template $VM_ID

rm focal-server-cloudimg-amd64.img
```

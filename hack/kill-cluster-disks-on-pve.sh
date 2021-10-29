#!/bin/bash
# This script should be launched on your Proxmox Node to clean up the
# Terraform mess it leaves behind when it explodes...
# *** WARNIING THIS WILL COMPLETELY NUKE ANY AND ALL DISKS ***
STORE=nas-zfs
VMIDS="4010,4011,4012,4020,4021,4022,4030,4031,4032"
VOLUMES=$(pvesm list $STORE | grep -E "${VMIDS//,/|}" |awk '{print $1}' | grep -v "Volid")
for volume in $VOLUMES
do
        # pvesm free nas-zfs:vm-4022-disk-0
        echo "pvesm free $volume"
done

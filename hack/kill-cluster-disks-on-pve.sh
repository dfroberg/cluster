#!/bin/bash
# This script should be launched on your Proxmox Node to clean up the
# Terraform mess it leaves behind when it explodes...
# *** WARNIING THIS WILL COMPLETELY NUKE ANY AND ALL DISKS ***

print_help()
{
	printf '%s\n' "Help"
	printf 'Usage: %s [-d, --delete] [-h|--help] <vmids>\n' "$0"
	printf '\t%s\n' "<vmids>: one or more VMIDs"
    printf '\t%s\n' "-d, --delete: optional flag to delete each deployment"
	printf '\t%s\n' "-h, --help: Prints help"
    printf '\t%s\n' "Example:"
    printf '\t%s\n' "$0 -d 4010 4011 4012 4020 4021 4022 4030 4031 4032"
}

PARAMS=""
while (( "$#" )); do
  case "$1" in
    -d|--delete)
      DELETE_FLAG=1
      shift
      ;;
    -h|--help)
        print_help
        exit 0
        ;;
    -h*)
        print_help
        exit 0
        ;;
    -*|--*=) # unsupported flags
      echo "✗ Error: Unsupported flag $1" >&2
      print_help
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"

STORE=nas-zfs

if [[ -z $1 ]] 
then
    echo "► VMID: all"
    vmselector=""
else
    vmarg=$@
    echo "► VMIDs: $vmarg"
    vmselector=${vmarg// /|}
    
fi

if [[ -z $vmarg ]] 
then
    echo "✗ No VMIDs specified! Displaying everything."
    DELETE_FLAG=0 # Can't DELETE EVERYTHING!

fi
VOLUMES=$(pvesm list $STORE | grep -E "$vmselector" |awk '{print $1}' | grep -v "Volid")
if [[ -z $VOLUMES ]] 
then
    echo "✗ No volumes found!"
fi
if [[ $DELETE_FLAG == 1 ]] 
then
    echo "► Deleting:"
else
    echo "► Simulating Deleting:"
fi
for volume in $VOLUMES
do
        echo "◎ Executing: pvesm free $volume"
        if [[ $DELETE_FLAG == 1 ]] 
        then
            pvesm free $volume
        fi
done
echo "✔ Done."
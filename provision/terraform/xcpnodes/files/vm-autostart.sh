#!/bin/bash

# xe vm-list for name-label, add in start order
vms=("postgres" "master01" "master03" "master03" "storage01" "storage02" "storage03" "worker01" "worker02" "worker03")
wait=42s

# No need to modify below
initwait=2.5m
vmslength=${#vms[@]}
log=/root/vma.log

start_vm () {
   echo -n "[$(date +"%T")] Starting $1 ... " >> ${log}
   /opt/xensource/bin/xe vm-start name-label=$1
   if [ $? -eq 0 ] 
     then 
       echo "Success" >> ${log}
     else 
       echo "FAILED" >> ${log}
   fi

   # Wait if not the last vm
   if [ "$1" != "${vms[${vmslength}-1]}" ]
     then
       echo "Waiting ${wait}" >> ${log}
       sleep ${wait}
   fi
}

echo "[$(date +"%T")] Running autostart script (Waiting ${initwait})" > ${log}
sleep ${initwait}

for vm in ${vms[@]}
do
  start_vm ${vm}
done

echo "[$(date +"%T")] Startup complete." >> ${log}
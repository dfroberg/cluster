#!/bin/bash
# Save the script and quit the editor when you're happy with it.
# Remember to set the script to be executable with `chmod a+x vm-autostart.sh`.
# Edit `/etc/rc.d/rc.local` with your favourite editor.
# At the bottom of the file, add a call to your newly create and executable script:
# ```
# `/root/vm-autostart.sh` 
# ```
# Save the file and quit the editor.
# Make the rc.local script executable:
# ```
# `chmod a+x /etc/rc.d/rc.local` 
# ```
# Next time your host restarts, your vms should start automatically. Remember to test the script manually by shutting down all your VMs and then running the script in the shell to see that you didn't inadvertently introduce any errors.
#
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
#!/bin/bash
if ! grep -Fxq "lxc.apparmor.profile: unconfined" /etc/pve/lxc/${vmid}.conf
then
# Only stop if needed
pct stop ${vmid}
# Modify the lxc conf
cat <<EOT>> /etc/pve/lxc/${vmid}.conf
lxc.apparmor.profile: unconfined
lxc.cgroup.devices.allow:
lxc.cgroup.devices.deny:
lxc.cap.drop:
lxc.mount.auto: "proc:rw sys:rw cgroup:rw:force"
EOT
else
    echo "Already configured"
fi
# Start regardless
pct start ${vmid}
# Take a Nap
sleep 60
exit 0
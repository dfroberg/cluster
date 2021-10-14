#!/bin/bash

export KUBECONFIG="/home/dfroberg/cluster/kubeconfig"

# PVCS_TO_RESTORE_RBD="prometheus-prometheus-operator-prometheus-db-prometheus-prometheus-operator-prometheus-0 data-hass-postgresql-postgresql-0 home-assistant unifi prometheus-operator-grafana mcsv-minecraft-datadir mc-minecraft-datadir rtorrent-flood-config radarr-config sonarr-config plex-kube-plex-config"
# PVCS_TO_RESTORE_RBD="bazarr-config-v1 jackett-config-v1 lidarr-config-v1 mylar-config-pvc-v1 prowlarr-config-v1 qbittorrent-config-v1 qbittorrent-vpn-config-v1 radarr-config-v1 readarr-config-v1 sabnzbd-config-v1 sonarr-config-v1"
NAMESPACE=media
PVCS_TO_RESTORE_RBD=$(kubectl get pvc -n $NAMESPACE | awk '{print $1}' | grep -v 'NAME')
BACKUP_LOCATION="/mnt/backups/cluster"

#### restore the stuff to ceph-block (rbd)
for pvc in $PVCS_TO_RESTORE_RBD
do
  PV=$(kubectl get pv --all-namespaces | grep "$pvc" | awk '{print $1}')
  CEPH_CSI_THING=$(kubectl describe pv "$PV" | grep VolumeHandle | awk '{print $2}' | sed 's/[0-9]*-[0-9]*-rook-ceph-[0-9]*-\(.*\)/\1/g')
  echo "===== Restoring $pvc ($CEPH_CSI_THING) from $BACKUP_LOCATION/${pvc}.tar.gz"
  tools="$(kubectl -n rook-ceph get pod -l "app=rook-direct-mount" -o jsonpath='{.items[0].metadata.name}')"
  echo "     ----- copying  $BACKUP_LOCATION/${pvc}.tar.gz to $tools:/tmp/"
  kubectl -n rook-ceph cp  "$BACKUP_LOCATION/${pvc}.tar.gz" "$tools":/tmp/
  echo "     ----- mapping, mounting, deleting contents of $pvc from $CEPH_CSI_THING and untarring /tmp/${pvc}.tar.gz to /tmp/rbd/ in the toolbox pod"
  kubectl -n rook-ceph exec -it "$tools" -- sh -c "DEV=\$(rbd map replicapool/csi-vol-$CEPH_CSI_THING) && mkdir -p /tmp/rbd && mount \$DEV /tmp/rbd && cd /tmp/rbd && tar zxf /tmp/${pvc}.tar.gz && cd /tmp; umount /tmp/rbd && rbd unmap \$DEV && rm /tmp/${pvc}.tar.gz"
done
#### restore the stuff to cephfs
for pvc in $PVCS_TO_RESTORE_CEPHFS
do
  PV=$(kubectl get pv --all-namespaces | grep "$pvc" | awk '{print $1}')
  CEPH_CSI_THING=$(kubectl describe pv "$PV" | grep VolumeHandle | awk '{print $2}' | sed 's/[0-9]*-[0-9]*-rook-ceph-[0-9]*-\(.*\)/\1/g')
  TOOLBOX_PATH="/tmp/registry/volumes/csi/csi-vol-$CEPH_CSI_THING"
  echo "===== Restoring $pvc ($CEPH_CSI_THING) from $BACKUP_LOCATION/${pvc}.tar.gz"
  tools="$(kubectl -n rook-ceph get pod -l "app=rook-direct-mount" -o jsonpath='{.items[0].metadata.name}')"
  echo "     ----- deleting contents of $TOOLBOX_PATH in the toolbox pod"
  kubectl -n rook-ceph exec -it "$tools" -- sh -c "rm -rf $TOOLBOX_PATH/{*,.*} 2> /dev/null"
  echo "     ----- copying $BACKUP_LOCATION/${pvc}.tar.gz to $tools:/tmp/"
  kubectl -n rook-ceph cp "$BACKUP_LOCATION/${pvc}.tar.gz" "$tools":/tmp/
  echo "     ----- untarring /tmp/${pvc}.tar.gz to $TOOLBOX_PATH/"
  kubectl -n rook-ceph exec -it "$tools" -- sh -c "cd $TOOLBOX_PATH/ && tar zxf /tmp/${pvc}.tar.gz && cd /tmp"
  kubectl -n rook-ceph exec -it "$tools" -- sh -c "rm /tmp/${pvc}.tar.gz"
done
#### restore the stuff to nfs-client
for pvc in $PVCS_TO_RESTORE_NFS
do
  PV=$(kubectl get pv --all-namespaces | grep "$pvc" | awk '{print $1}')
  NFS_PATH=$(kubectl get pv "$PV" -o=jsonpath='{.spec.nfs.path}')
  echo "===== Restoring $pvc ($NFS_PATH) from $BACKUP_LOCATION/$pvc"
  ssh root@proxmox sh -c "rm -rf $NFS_PATH/* 2> /dev/null; rm -rf $NFS_PATH/.* 2> /dev/null; cd $NFS_PATH; tar zxf $BACKUP_LOCATION/${pvc}.tar.gz"
done
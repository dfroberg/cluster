#!/bin/bash -e
# Velero specific.
# Deletes PVCs using the <deployment>-config-v<X> naming convention
#
cd ~/cluster
export KUBECONFIG="/home/dfroberg/cluster/kubeconfig"
#export RESOURCESTORESTORE="secrets,configmaps,persistentvolumeclaims,persistentvolumes"
export RESOURCESTORESTORE="pods,persistentvolumeclaims,persistentvolumes"
ALREADYRUNNING=$(velero get restores | grep -c -E "New|InProgress" || true)

if [[ "$ALREADYRUNNING" != "0" ]]
then
    echo "► Restoration already running 
    Skipping, check 
        velero get restores
    clear queue with;
        velero restore delete --all
"
    exit 1
fi


NAMESPACE=media
DEPLOYMENTS=$(kubectl get deploy -n $NAMESPACE -owide | grep "$pvc" | awk '{print $1}' | grep -v "NAME")
# Turn off automatic rebuilds
echo "► Restoring in progress"
flux suspend helmrelease --all -n media
flux suspend kustomization apps
echo "✔ Suspended cluster rebuild of apps"
# Scale deployments to 0
for deployment in $DEPLOYMENTS
do
    echo "► Scaling $deployment"
    kubectl scale -n $NAMESPACE deploy/$deployment --replicas 0 
done
echo "✔ Scaled all deployments to zero."
sleep 5

# Remove PVCs & PVs
for deployment in $DEPLOYMENTS
do
    PVC="$(kubectl get pvc -n $NAMESPACE | grep -e "$deployment-config" | awk '{print $1}')"
    if [[ ! -z "$PVC" ]]
    then
        echo "► Deleting deployment $deployment"
        kubectl delete deployment $deployment -n $NAMESPACE --wait 
        echo "► Deleting $PVC in $deployment"
        kubectl delete pvc $PVC -n $NAMESPACE --wait 
    else
        echo "► No PVC in $deployment, skipping."
    fi
done
echo "✔ Done deleting!"
sleep 30
# TBD: Make SURE everything is deleted

echo "► Schedule restorations:"
#for deployment in $DEPLOYMENTS
#do
#    echo "► Restoring $deployment"
    velero restore create --from-backup media-backup --restore-volumes=true #--selector "app.kubernetes.io/name=$deployment" --include-resources $RESOURCESTORESTORE
#    sleep 1 # for some reason duplicates are created if we don't wait
#done

echo "► Currently scheduled:"
velero get restores
echo "► Waiting for the scheduled restores to complete..."

while [[ "$(velero get restores | grep -c -E "New|InProgress" || true)" != "0" ]]; 
do
    sleep 1
    echo -n "."
done
echo "✔ Done restoring!"

echo "► Completed:"
velero get restores
sleep 10

#flux resume kustomization apps
#flux resume helmrelease --all -n media

echo "✔ Resumed cluster rebuild of apps"

# To clean up run;
# velero restore delete --all

# Velero specific.
# Deletes PVCs using the <deployment>-config-v<X> naming convention
#

export KUBECONFIG="/home/dfroberg/cluster/kubeconfig"
RUNNING=$(velero get restores | grep -c -E "New|InProgress" || true)

if [$RUNNING -gt 0]
then
    echo "► Restoration already running\n   Skipping, check \n     velero get restores\n  clear queue with;\n    velero get restores "
    exit 1
else

    NAMESPACE=media
    DEPLOYMENTS=$(kubectl get deploy -n $NAMESPACE -owide | grep "$pvc" | awk '{print $1}' | grep -v "NAME")
    # Turn off automatic rebuilds
    echo "► Restoring in progress"
    cd ~/cluster
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
    sleep 30
    # Remove PVCs & PVs
    for deployment in $DEPLOYMENTS
    do
        PVC=$(kubectl get pvc -n $NAMESPACE | grep -e "$deployment-config" | awk '{print $1}')
        echo "► Deleting $PVC in $deployment"
        kubectl delete pvc $PVC -n $NAMESPACE --wait

    done
    echo "✔ Done deleting!"
    sleep 30


    echo "► Begin restoration..."
    for deployment in $DEPLOYMENTS
    do
        echo "► Restoring $deployment"
        velero restore create --from-backup media-backup --selector "app.kubernetes.io/name=$deployment" --restore-volumes=true --include-resources secrets,configmaps,persistentvolumeclaims,persistentvolumes
    done
    echo "► Waiting for the restores to complete..."
    while [$(velero get restores | grep -c -E "New|InProgress" || true) -gt 0]; 
    do
        sleep 1
        echo -n "."
    done
    echo "✔ Done restoring!"

    flux resume helmrelease --all -n media
    flux resume kustomization apps
    echo "✔ Resumed cluster rebuild of apps"

    # To clean up run;
    # velero restore delete --all
fi
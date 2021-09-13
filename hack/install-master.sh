#!/bin/bash
# This script depends on setting up a TCP LoadBalancer first

export USER=dfroberg
export SERVER_IP=192.168.30.70
export K3S_VERSION=v1.21.4+k3s1
export LB=192.168.30.60

echo "Master 01"
k3sup install \
    --host=192.168.30.70 \
    --user=$USER \
    --cluster \
    --k3s-version=$K3S_VERSION \
    --k3s-extra-args="\
--node-taint CriticalAddonsOnly=true:NoExecute \
--node-label master=yes \
--tls-san 192.168.30.60 \
--tls-san 192.168.30.70 \
--tls-san 192.168.30.71 \
--tls-san 192.168.30.72 \
--write-kubeconfig-mode 644 \
--disable servicelb \
--disable traefik \
--disable metrics-server \
"
sleep 5

# Replace Master01 ip with LB IP
sed --in-place='' --expression="s/$SERVER_IP/$LB/g" /home/dfroberg/cluster/kubeconfig 

sleep 5
echo "Master 02"
export NEXT_SERVER_IP=192.168.30.71

k3sup join \
  --ip $NEXT_SERVER_IP \
  --user $USER \
  --server-user $USER \
  --server-ip $LB \
  --server \
  --k3s-version=$K3S_VERSION \
  --k3s-extra-args="\
--node-taint CriticalAddonsOnly=true:NoExecute \
--node-label master=yes \
--tls-san 192.168.30.60 \
--tls-san 192.168.30.70 \
--tls-san 192.168.30.71 \
--tls-san 192.168.30.72 \
--write-kubeconfig-mode 644 \
--disable servicelb \
--disable traefik \
--disable metrics-server \
"
sleep 5
echo "Master 03"
export NEXT_SERVER_IP=192.168.30.72

k3sup join \
  --ip $NEXT_SERVER_IP \
  --user $USER \
  --server-user $USER \
  --server-ip $LB \
  --server \
  --k3s-version=$K3S_VERSION \
  --k3s-extra-args="\
--node-taint CriticalAddonsOnly=true:NoExecute \
--node-label master=yes \
--tls-san 192.168.30.60 \
--tls-san 192.168.30.70 \
--tls-san 192.168.30.71 \
--tls-san 192.168.30.72 \
--write-kubeconfig-mode 644 \
--disable servicelb \
--disable traefik \
--disable metrics-server \
"

sleep 5

# Workers
export SERVER_IP=$LB
export NEXT_SERVER_IP=192.168.30.80
echo "Worker 01"
k3sup join \
  --ip $NEXT_SERVER_IP \
  --user $USER \
  --server-user $USER \
  --server-ip $SERVER_IP \
  --k3s-version=$K3S_VERSION \
  --k3s-extra-args="\
--node-label worker=yes \
"

sleep 5

export NEXT_SERVER_IP=192.168.30.81
echo "Worker 01"
k3sup join \
  --ip $NEXT_SERVER_IP \
  --user $USER \
  --server-user $USER \
  --server-ip $SERVER_IP \
  --k3s-version=$K3S_VERSION \
  --k3s-extra-args="\
--node-label worker=yes \
"

sleep 5

export NEXT_SERVER_IP=192.168.30.82
echo "Worker 02"
k3sup join \
  --ip $NEXT_SERVER_IP \
  --user $USER \
  --server-user $USER \
  --server-ip $SERVER_IP \
  --k3s-version=$K3S_VERSION \
  --k3s-extra-args="\
--node-label worker=yes \
"

sleep 5

# Storage
export NEXT_SERVER_IP=192.168.30.90
echo "Storage 01"
k3sup join \
  --ip $NEXT_SERVER_IP \
  --user $USER \
  --server-user $USER \
  --server-ip $SERVER_IP \
  --k3s-version=$K3S_VERSION \
  --k3s-extra-args="\
--node-label storage=yes \
"

sleep 5
export NEXT_SERVER_IP=192.168.30.91
echo "Storage 02"
k3sup join \
  --ip $NEXT_SERVER_IP \
  --user $USER \
  --server-user $USER \
  --server-ip $SERVER_IP \
  --k3s-version=$K3S_VERSION \
  --k3s-extra-args="\
--node-label storage=yes \
"

sleep 5
export NEXT_SERVER_IP=192.168.30.92
echo "Storage 03"
k3sup join \
  --ip $NEXT_SERVER_IP \
  --user $USER \
  --server-user $USER \
  --server-ip $SERVER_IP \
  --k3s-version=$K3S_VERSION \
  --k3s-extra-args="\
--node-label storage=yes \
"

echo "Create flux-system namespace"
export KUBECONFIG=/home/dfroberg/cluster/kubeconfig
kubectl config set-context default
kubectl create namespace flux-system

echo "Apply Initial Cluster Secret Keys"
kubectl apply -f ../cluster-secrets/cluster/sops-gpg.yaml -n flux-system

echo "Patch system to ensure local-path is not default as it collides with rook-ceph"
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

echo "Bootstrap"
flux bootstrap github --owner=dfroberg --repository=cluster --private=false --personal=true --path=/cluster/base/ --token-auth --reconcile


# Setup some helpers
alias kdk="k describe kustomizations.kustomize.toolkit.fluxcd.io -A"

echo "Done."
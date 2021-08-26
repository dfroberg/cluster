#!/bin/bash
# This script depends on setting up a TCP LoadBalancer first

export USER=dfroberg
export SERVER_IP=192.168.30.70
export K3S_VERSION=v1.21.4+k3s1
export LB=192.168.30.60

k3sup install \
    --host=192.168.30.70 \
    --user=$USER \
    --cluster \
    --k3s-version=$K3S_VERSION \
    --k3s-extra-args='\
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
      '

sleep 5

export NEXT_SERVER_IP=192.168.30.71

k3sup join \
  --ip $NEXT_SERVER_IP \
  --user $USER \
  --server-user $USER \
  --server-ip $LB \
  --server \
  --k3s-version=$K3S_VERSION \
  --k3s-extra-args='\
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
      '
sleep 5
export NEXT_SERVER_IP=192.168.30.72

k3sup join \
  --ip $NEXT_SERVER_IP \
  --user $USER \
  --server-user $USER \
  --server-ip $LB \
  --server \
  --k3s-version=$K3S_VERSION \
  --k3s-extra-args='\
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
      '

sleep 5

# Workers
export SERVER_IP=$LB
export NEXT_SERVER_IP=192.168.30.80

k3sup join \
  --ip $NEXT_SERVER_IP \
  --user $USER \
  --server-user $USER \
  --server-ip $SERVER_IP \
  --server \
  --k3s-version=$K3S_VERSION \
  --k3s-extra-args='\
      --node-label worker=yes \
      --disable servicelb \
      --disable traefik \
      --disable metrics-server \
      '

sleep 5

export NEXT_SERVER_IP=192.168.30.81

k3sup join \
  --ip $NEXT_SERVER_IP \
  --user $USER \
  --server-user $USER \
  --server-ip $SERVER_IP \
  --server \
  --k3s-version=$K3S_VERSION \
  --k3s-extra-args='\
      --node-label worker=yes \
      --disable servicelb \
      --disable traefik \
      --disable metrics-server \
      '

sleep 5

export NEXT_SERVER_IP=192.168.30.82

k3sup join \
  --ip $NEXT_SERVER_IP \
  --user $USER \
  --server-user $USER \
  --server-ip $SERVER_IP \
  --server \
  --k3s-version=$K3S_VERSION \
  --k3s-extra-args='\
      --node-label worker=yes \
      --disable servicelb \
      --disable traefik \
      --disable metrics-server \
      '

sleep 5

# Storage
export NEXT_SERVER_IP=192.168.30.90

k3sup join \
  --ip $NEXT_SERVER_IP \
  --user $USER \
  --server-user $USER \
  --server-ip $SERVER_IP \
  --server \
  --k3s-version=$K3S_VERSION \
  --k3s-extra-args='\
      --node-label storage=yes \
      --disable servicelb \
      --disable traefik \
      --disable metrics-server \
      '

sleep 5
export NEXT_SERVER_IP=192.168.30.91

k3sup join \
  --ip $NEXT_SERVER_IP \
  --user $USER \
  --server-user $USER \
  --server-ip $SERVER_IP \
  --server \
  --k3s-version=$K3S_VERSION \
  --k3s-extra-args='\
      --node-label storage=yes \
      --disable servicelb \
      --disable traefik \
      --disable metrics-server \
      '

sleep 5
export NEXT_SERVER_IP=192.168.30.92

k3sup join \
  --ip $NEXT_SERVER_IP \
  --user $USER \
  --server-user $USER \
  --server-ip $SERVER_IP \
  --server \
  --k3s-version=$K3S_VERSION \
  --k3s-extra-args='\
      --node-label storage=yes \
      --disable servicelb \
      --disable traefik \
      --disable metrics-server \
      '

sleep 5
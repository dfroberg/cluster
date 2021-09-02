#!/bin/bash
# This script depends on setting up a TCP LoadBalancer first

export USER=dfroberg
export SERVER_IP=192.168.30.70
export K3S_VERSION=v1.21.4+k3s1
export LB=192.168.30.60

export NEXT_SERVER_IP=$1
echo "Storage 03"
k3sup join \
  --ip $NEXT_SERVER_IP \
  --user $USER \
  --server-user $USER \
  --server-ip $SERVER_IP \
  --k3s-version=$K3S_VERSION \
  --k3s-extra-args="\
--node-label worker=yes \
"
echo "Done."
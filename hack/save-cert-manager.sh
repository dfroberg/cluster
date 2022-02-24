#!/bin/bash
# This script saves cert-manager resources to save on reissue
kubectl get --all-namespaces -oyaml issuer,clusterissuer,cert > cert-manager-backup.yaml
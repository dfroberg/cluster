#!/bin/bash
# cd into cluster repo
cd ~/cluster/
# perform the substs
envsubst < ./tmpl/.sops.yaml > ./.sops.yaml
envsubst < ./tmpl/cluster-secrets.sops.yaml > ./cluster/base/cluster-secrets.sops.yaml
envsubst < ./tmpl/cluster-settings.yaml > ./cluster/base/cluster-settings.yaml
envsubst < ./tmpl/gotk-sync.yaml > ./cluster/base/flux-system/gotk-sync.yaml
envsubst < ./tmpl/secret.sops.yaml > ./cluster/core/cert-manager/secret.sops.yaml

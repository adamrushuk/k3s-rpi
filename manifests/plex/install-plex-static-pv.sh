#!/bin/bash

# testing nfs config

# IMPORTANT: ensure there are multiple PVs/PVCs for Plex, unless you're using Dynamic Provisioning

# create namespace
kubectl create namespace media

# persistent volume (pv)
kubectl apply -f ./manifests/plex/pv-plex.yml
kubectl get pv
kubectl describe pv nfs

# persistent volume claim (pvc)
kubectl apply -f ./manifests/plex/pvc-plex.yml
kubectl get pvc -n media
kubectl describe pvc nfs -n media

# rendered helm template (also shown if --debug used with helm install)
helm template plex charts/kube-plex --values \
  charts/values/media.plex.values.yml > plex_rendered.yml

# install plex
# https://github.com/munnerz/kube-plex
helm install plex charts/kube-plex \
  --values charts/values/media.plex.values.yml \
  --namespace media --debug

# check
helm list -A
kubectl get all,pv,pvc -n media

# check files on node
tree /mnt/
ll /mnt/ssd/media

# [optional] cleanup
helm uninstall plex --namespace media
kubectl delete -f ./manifests/plex/pvc-plex.yml
kubectl delete -f ./manifests/plex/pv-plex.yml
# kubectl delete pvc,pv --all

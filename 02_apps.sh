#!/bin/bash

# Plex (dynamic PVs with NFS)

# create namespace
kubectl create namespace media

# create ingress
kubectl apply -f ./manifests/media.ingress.yml

# install nfs-client-provisioner for dynamic pv support
# https://github.com/helm/charts/tree/master/stable/nfs-client-provisioner
helm install nfs-provisioner stable/nfs-client-provisioner \
    --set nfs.server=192.168.1.10 \
    --set nfs.path=/mnt/ssd/media \
    --set image.repository=quay.io/external_storage/nfs-client-provisioner-arm \
    --set storageClass.name=nfs-client \
    --namespace media #--debug
# misc values
# --set nfs.mountOptions=

# persistent volume claim (pvc) - uses dynamic pv
kubectl apply -f ./manifests/plex/pvc-dynamic-plex.yml
kubectl get pvc -n media
kubectl describe pvc -n media

# install plex
# https://github.com/munnerz/kube-plex
helm install plex charts/kube-plex \
  --values charts/values/media.plex.values.yml \
  --namespace media #--debug

# check
helm list -A
kubectl get all,pv,pvc -n media

# [optional] cleanup
helm uninstall plex --namespace media
kubectl delete -f ./manifests/plex/pvc-dynamic-plex.yml
helm uninstall nfs-provisioner --namespace media
# kubectl delete pvc,pv --all

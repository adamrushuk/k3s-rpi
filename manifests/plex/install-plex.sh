#!/bin/bash

# testing nfs config

# IMPORTANT: ensure there

# create namespace
kubectl create namespace media
kubectl get all,pv,pvc -n media

# TESTING plex
# NOTE: storage class is NOT required for nfs on k3s
# kubectl delete -f ./manifests/plex/nfs_sc.yml
# kubectl apply -f ./manifests/plex/nfs_sc.yml
# kubectl get sc
# kubectl describe sc managed-nfs-storage

# deploy persistent volume (pv)
kubectl delete -f ./manifests/plex/pv-plex.yml
kubectl apply -f ./manifests/plex/pv-plex.yml
kubectl get pv
kubectl describe pv nfs

# create persistent volume claim (pvc)
kubectl delete -f ./manifests/plex/pvc-plex.yml
kubectl apply -f ./manifests/plex/pvc-plex.yml
kubectl get pvc -n media
kubectl describe pvc nfs -n media

# show rendered helm template
helm template plex charts/kube-plex --values \
  charts/values/media.plex.values.yml > plex_rendered.yml

# install plex
helm list -A
helm uninstall plex --namespace media

helm install plex charts/kube-plex \
  --values charts/values/media.plex.values.yml \
  --namespace media --debug


# check
kubectl get all,pv,pvc -n media

# check on node
tree /mnt/
ll /mnt/ssd/media
cat /mnt/ssd/media/index.html
tail -f /mnt/ssd/media/index.html

# check within pod
kubectl exec -it nfs-busybox-864d85c779-x5wjl sh -n media
df -h
ls -la /mnt/
tail -f /mnt/localpod/index.html

# [optional] cleanup
kubectl delete pvc,pv --all

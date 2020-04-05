#!/bin/bash

# testing nfs config

# create namespace
kubectl create namespace media
kubectl get all,pv,pvc -n media

# TESTING NFS
# NOTE: storage class is NOT required for nfs on k3s
# kubectl delete -f ./manifests/nfs/nfs_sc.yml
# kubectl apply -f ./manifests/nfs/nfs_sc.yml
# kubectl get sc
# kubectl describe sc managed-nfs-storage

# deploy persistent volume (pv)
kubectl delete -f ./manifests/nfs/nfs_pv.yml
kubectl apply -f ./manifests/nfs/nfs_pv.yml
kubectl get pv
kubectl describe pv nfs

# create persistent volume claim (pvc)
kubectl delete -f ./manifests/nfs/nfs_pvc.yml
kubectl apply -f ./manifests/nfs/nfs_pvc.yml
kubectl get pvc -n media
kubectl describe pvc nfs -n media

# create deployment to test pvc with multiple pods
kubectl delete -f ./manifests/nfs/nfs_deploy.yml
kubectl apply -f ./manifests/nfs/nfs_deploy.yml
kubectl get pod -n media
kubectl describe deploy/nfs-busybox -n media

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

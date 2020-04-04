#!/bin/bash

# https://kauri.io/self-host-your-media-center-on-kubernetes-with-plex-sonarr-radarr-transmission-and-jackett/8ec7c8c6bf4e4cc2a2ed563243998537/a

# create namespace
kubectl create namespace media

kubectl get all,pv,pvc -n media


# TESTING NFS
# create storage class
# kubectl delete -f ./manifests/storage_class.yml
# kubectl apply -f ./manifests/storage_class.yml
# kubectl get sc
# kubectl describe sc managed-nfs-storage

# deploy persistent volume (pv)
kubectl delete -f ./manifests/nfs_pv.yml
kubectl apply -f ./manifests/nfs_pv.yml
kubectl get pv
kubectl describe pv nfs

# create persistent volume claim (pvc)
kubectl delete -f ./manifests/nfs_pvc.yml
kubectl apply -f ./manifests/nfs_pvc.yml
kubectl get pvc -n media
kubectl describe pvc nfs -n media

# create pod to test pvc
kubectl delete -f ./manifests/nfs_pod.yml
kubectl apply -f ./manifests/nfs_pod.yml
kubectl get pod -n media
kubectl describe pod volume-debugger -n media

# check within pod
kubectl exec -it volume-debugger sh -n media
ls -la /data
touch /data/test_$(date +"%Y%m%d-%H%M%S")
exit

# [optional] cleanup
kubectl delete pvc,pv --all










# deploy persistent volume (pv)
kubectl delete -f ./manifests/media.persistentvolume.yml
kubectl apply -f ./manifests/media.persistentvolume.yml
kubectl get pv
kubectl describe pv media-ssd

# create persistent volume claim (pvc)
kubectl delete -f ./manifests/media.persistentvolumeclaim.yml
kubectl apply -f ./manifests/media.persistentvolumeclaim.yml
kubectl get pvc -n media
kubectl describe pvc media-ssd

# check
kubectl get pv,pvc -A
kubectl describe pv
kubectl describe pvc -n media
kubectl get sc


# [optional] cleanup
kubectl delete pvc,pv --all











# create media ingress
kubectl apply -f ./manifests/media.ingress.yml

# check http://media.192.168.1.30.nip.io

# heml repository - add bananaspliff
helm repo add bananaspliff https://bananaspliff.github.io/geek-charts
helm repo update

# TODO: BitTorrent client - Transmission over VPN

# TODO: Torrent Providers Aggregator- Jackett over VPN

# TODO: TV Show Library Management - Sonarr
# login to a worker node and create folder
ssh pi@pi1
sudo mkdir -p /mnt/ssd/media/configs/sonarr/
tree /mnt/ssd/
media.sonarr.values.yml


# TODO: Movie Library Management - Radarr

# ! WIP
# media server - plex
helm list -A
helm uninstall plex --namespace media

helm install plex charts/kube-plex/charts/kube-plex/ \
  --values charts/values/media.plex.values.yml \
  --namespace media --debug

# check
kubectl get all,pv,pvc -A
kubectl get pods -n media -l app=kube-plex -o wide -w
kubectl get services -n media -l app=kube-plex -o wide
kubectl get deploy --namespace media --watch

kubectl get events --sort-by=.metadata.creationTimestamp --namespace media
kubectl get events --namespace media --watch

kubectl get deploy -n media
kubectl logs -n media -l app=kube-plex

# ? Tshoot
# show rendered helm template
helm template plex charts/kube-plex/charts/kube-plex/ --values \
  charts/values/media.plex.values.yml >plex_rendered.yml

# show storage
kubectl get pv,pvc -A
kubectl describe pvc -A

helm list -A

kubectl describe deploy/plex-kube-plex -n media

# debug
kubectl delete -f ./manifests/pvc-debugger.yml
kubectl apply -f ./manifests/pvc-debugger.yml
kubectl exec -it volume-debugger sh -n media

kubectl delete -f ./manifests/pvc-debugger2.yml
kubectl apply -f ./manifests/pvc-debugger2.yml
kubectl exec -it volume-debugger2 sh -n media

cd /data
ls -la
vi test
cat test

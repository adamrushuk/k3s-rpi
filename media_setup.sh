#!/bin/bash

# https://kauri.io/self-host-your-media-center-on-kubernetes-with-plex-sonarr-radarr-transmission-and-jackett/8ec7c8c6bf4e4cc2a2ed563243998537/a

# create namespace
kubectl create namespace media

# create storage class
kubectl apply -f ./manifests/storage_class.yml

# deploy the persistent volume (pv)
kubectl apply -f ./manifests/media.persistentvolume.yml
kubectl delete -f ./manifests/media.persistentvolume.yml

kubectl apply -f ./manifests/pvwithnfs.yaml

kubectl delete pvc,pv --all
kubectl delete pv --all

# check
kubectl get pv

# create the persistent volume claim (pvc)
kubectl apply -f ./manifests/media.persistentvolumeclaim.yml
kubectl delete -f ./manifests/media.persistentvolumeclaim.yml

# check
kubectl get pv,pvc -A
kubectl describe pv
kubectl describe pvc -n media
kubectl get sc

# create media ingress
kubectl apply -f ./manifests/media.ingress.yml

# check http://media.192.168.1.30.nip.io


# heml repository - add bananaspliff
helm repo add bananaspliff https://bananaspliff.github.io/geek-charts
helm repo update

# TODO: BitTorrent client - Transmission over VPN

# TODO: Torrent Providers Aggregator- Jackett over VPN

# TODO: TV Show Library Management - Sonarr

# TODO: Movie Library Management - Radarr



# ! WIP
# media server - plex
helm list -A
helm uninstall plex --namespace media

helm install plex charts/kube-plex/charts/kube-plex/ \
  --values charts/values/media.plex.values.yml \
  --namespace media

# check
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
  charts/values/media.plex.values.yml > plex_rendered.yml

# show storage
kubectl get pv,pvc -A
kubectl describe pvc -A

helm list -A

kubectl describe deploy/plex-kube-plex -n media

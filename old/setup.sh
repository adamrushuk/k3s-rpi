#!/bin/bash

# Install k3s on RPi cluster
# https://kauri.io/install-and-configure-a-kubernetes-cluster-with-k3s-to-self-host-applications/418b3bc1e0544fbc955a4bbba6fff8a9/a

# vars
HELM_VERSION="3.1.2"

# update windows hosts file for local computer, as wsl overwrites from this:
# C:\Windows\System32\drivers\etc\hosts
# sudo nano /etc/hosts
192.168.1.10    pi0
192.168.1.11    pi1
192.168.1.12    pi2
192.168.1.13    pi3

# ssh
# copy keys to pi's
ssh-copy-id pi@pi0
ssh-copy-id pi@pi1
ssh-copy-id pi@pi2
ssh-copy-id pi@pi3



# storage
# https://www.instructables.com/id/Turn-Raspberry-Pi-into-a-Network-File-System-versi/
# nfs server
# login to master node
ssh pi@pi0

# install nfs server
sudo apt-get install nfs-common nfs-kernel-server

# create folder to share
sudo mkdir -p /mnt/ssd/media

# set perms
sudo chown -R pi:pi /mnt/ssd/media
sudo find /mnt/ssd/ -type d -exec chmod 777 {} \;
sudo find /mnt/ssd/ -type f -exec chmod 777 {} \;
ls -la /mnt/
tree /mnt

# create test file
sudo nano /mnt/ssd/hello.txt
Hello NFS

cat /mnt/ssd/hello.txt

# note gid and uid - prob both 1000
id pi

# add share to exports
sudo nano /etc/exports
/mnt/ssd *(rw,all_squash,insecure,async,no_subtree_check,anonuid=1000,anongid=1000)

cat /etc/exports

# start server
sudo exportfs -ra
systemctl list-unit-files | grep nfs


# nfs clients
# do these steps on all worker nodes, eg:
ssh pi@pi1
ssh pi@pi2
ssh pi@pi3
...

# install nfs client
sudo apt-get install nfs-common -y

# show nfs server mounts
showmount -e 192.168.1.10

# create mount folder
sudo mkdir -p /mnt/ssd
sudo chown -R pi:pi /mnt/ssd/
ls -l /mnt

# [optional] temp mount for testing
sudo mount.nfs4 192.168.1.10:/mnt/ssd /mnt/ssd
ls -l /mnt/ssd

# persistent mount
cat /etc/fstab
sudo nano /etc/fstab
192.168.1.10:/mnt/ssd   /mnt/ssd   nfs    rw  0  0
sudo reboot



# Install Helm
sudo wget -O helm.tar.gz "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz"
tar -zxvf helm.tar.gz
sudo mv linux-amd64/helm /bin/helm
sudo rm -fr linux-amd64/ helm.tar.gz

# add charts
helm repo add stable https://kubernetes-charts.storage.googleapis.com


# Install MetalLB - Kubernetes Load Balancer
# 192.168.1.30-40 range
helm install metallb stable/metallb --namespace kube-system \
  --set configInline.address-pools[0].name=default \
  --set configInline.address-pools[0].protocol=layer2 \
  --set configInline.address-pools[0].addresses[0]=192.168.1.30-192.168.1.40

# check
kubectl get pods -n kube-system -l app=metallb -o wide -w


# Install Nginx - Web Proxy
helm install nginx-ingress stable/nginx-ingress --namespace kube-system \
    --set controller.image.repository=quay.io/kubernetes-ingress-controller/nginx-ingress-controller-arm \
    --set controller.image.tag=0.25.1 \
    --set controller.image.runAsUser=33 \
    --set defaultBackend.enabled=false

# check
kubectl get pods -n kube-system -l app=nginx-ingress -o wide -w
kubectl get services -n kube-system -l app=nginx-ingress -o wide


# Install cert-manager
kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.14/deploy/manifests/00-crds.yaml
helm repo add jetstack https://charts.jetstack.io && helm repo update
helm install cert-manager jetstack/cert-manager --namespace kube-system

# check
kubectl get pods -n kube-system -l app.kubernetes.io/instance=cert-manager -o wide -w

# Configure the certificate issuers
kubectl apply -f manifests/cluster_issuer_staging.yml
kubectl apply -f manifests/cluster_issuer_prod.yml

# check
kubectl get clusterissuer -o wide -w


# check all resources
kubectl get all,clusterissuer -A



# kubernetes-dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc7/aio/deploy/recommended.yaml

# check
kubectl get pods -n kubernetes-dashboard -w

# create admin-user
kubectl apply -f manifests/kube-dashboard.yml

# Now we have a secure channel, you can access kubernetes-dashboard via the following URL:
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/.
# Select "Token", copy/paste the token previously retrieved and click on "Sign in".
kubectl -n kubernetes-dashboard describe secret "$(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')"

# show dashboard
kubectl proxy

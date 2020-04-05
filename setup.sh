#!/bin/bash

# k3s setup with docker

# k3s master node with docker
export K3S_KUBECONFIG_MODE="644"
curl -sfL https://get.k3s.io | sh -s server --docker

# check
sudo systemctl status k3s
kubectl get nodes -o wide
kubectl get pods -A -o wide

# save access token
sudo cat /var/lib/rancher/k3s/server/node-token


# k3 worker nodes with docker
export K3S_KUBECONFIG_MODE="644"
export K3S_URL="https://192.168.1.10:6443"
export K3S_TOKEN="K10a6c3fee8395f1fb974f8dacc555403478607d8f4288396eaf925cfe74a3f8e08::server:9cf2afbde4403daebf601e323e91b965"
curl -sfL https://get.k3s.io | sh -s agent --docker

# check from master
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl get all -A


# copy k3s config from master node to local machine, and
# replace ip
scp pi@pi0:/etc/rancher/k3s/k3s.yaml ~/.kube/config
sed -i 's/127\.0\.0\.1/192\.168\.1\.10/g' ~/.kube/config

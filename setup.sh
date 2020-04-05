#!/bin/bash

# k3s setup with docker

# k3s master node with docker
export K3S_KUBECONFIG_MODE="644"
export INSTALL_K3S_EXEC=" --no-deploy servicelb --no-deploy traefik"
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
export K3S_TOKEN="K3S_TOKEN"
curl -sfL https://get.k3s.io | sh -s agent --docker

# check from master
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl get all -A


# copy k3s config from master node to local machine (WSL), and
# replace ip
scp pi@pi0:/etc/rancher/k3s/k3s.yaml ~/.kube/config
sed -i 's/127\.0\.0\.1/192\.168\.1\.10/g' ~/.kube/config

# [optional] copy k3s config from WSL to other hosts
cat ~/.kube/config


# Install MetalLB - Kubernetes Load Balancer
# 192.168.1.30-40 range
helm install metallb stable/metallb --namespace kube-system \
  --set configInline.address-pools[0].name=default \
  --set configInline.address-pools[0].protocol=layer2 \
  --set configInline.address-pools[0].addresses[0]=192.168.1.30-192.168.1.40

# check
kubectl get pods -n kube-system -l app=metallb -o wide -w
kubectl get all -A


# Install Nginx - Web Proxy
helm install nginx-ingress stable/nginx-ingress --namespace kube-system \
    --set controller.image.repository=quay.io/kubernetes-ingress-controller/nginx-ingress-controller-arm \
    --set controller.image.tag=0.25.1 \
    --set controller.image.runAsUser=33 \
    --set defaultBackend.enabled=true \
    --set defaultBackend.image.repository=gcr.io/google_containers/defaultbackend-arm \
    --set defaultBackend.image.tag=1.5 #\
    # --set defaultBackend.image.runAsUser=33

# check
kubectl get pods -n kube-system -l app=nginx-ingress -o wide -w
kubectl get services -n kube-system -l app=nginx-ingress -o wide
kubectl get all -A


# Install cert-manager
kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.14/deploy/manifests/00-crds.yaml
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace kube-system

# check
kubectl get pods -n kube-system -l app.kubernetes.io/instance=cert-manager -o wide -w

# Configure the certificate issuers
kubectl apply -f manifests/cert-manager/cluster_issuer_staging.yml
kubectl apply -f manifests/cert-manager/cluster_issuer_prod.yml

# check
kubectl get clusterissuer -o wide -w




# check all resources
kubectl get all,clusterissuer -A

# Cleanup
helm list -A
helm uninstall nginx-ingress -n kube-system

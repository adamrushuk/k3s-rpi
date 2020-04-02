# Install k3s on RPi cluster
# https://kauri.io/install-and-configure-a-kubernetes-cluster-with-k3s-to-self-host-applications/418b3bc1e0544fbc955a4bbba6fff8a9/a

# vars
HELM_VERSION="3.1.2"

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

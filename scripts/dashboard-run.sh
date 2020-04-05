#!/bin/bash

# source: https://limpygnome.com/2019/09/21/raspberry-pi-kubernetes-cluster/

MASTER="pi@192.168.1.10"

# Print token for login
TOKEN_COMMAND="kubectl -n kube-system describe secret \$(kubectl -n kube-system get secret | grep admin-user | awk '{print \$1}')"

echo "Dumping token for dashboard..."
ssh ${MASTER} -C "${TOKEN_COMMAND}"

echo "Login:"
echo "  http://localhost:8080/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login"

# Create SSH tunnel to k8 master and run proxy
echo "Creating proxy tunnel to this machine from master..."
ssh -L 8080:localhost:8080 ${MASTER} -C "kubectl proxy --port=8080 || true"

echo "Terminate proxy..."
ssh ${MASTER} -C "pkill kubectl"

#!/bin/bash

# kubernetes-dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc7/aio/deploy/recommended.yaml

# check
kubectl get pods -n kubernetes-dashboard -w

# create admin-user
kubectl apply -f manifests/dashboard/kube-dashboard.yml

# Now we have a secure channel, you can access kubernetes-dashboard via the following URL:
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/.
# Select "Token", copy/paste the token previously retrieved and click on "Sign in".
kubectl -n kubernetes-dashboard describe secret "$(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')"

# show dashboard
kubectl proxy

#!/bin/bash

NS=ingress-nginx
echo "Ingress-Nginx running version (namespace: $NS)"

PODNAME=$(kubectl -n $NS get pods -l app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/component=controller -o name)

kubectl exec -it -n $NS $PODNAME -- /nginx-ingress-controller --version
#!/bin/bash

kubectl apply -f https://k8s.io/examples/admin/dns/dnsutils.yaml

echo "After the dsnutil pod is running:"
echo " kubectl exec -i -t dnsutils -- nslookup <url>"
echo
echo "To end the pod: "
echo " kubectl delete pod dnsutils"

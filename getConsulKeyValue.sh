#!/bin/bash

exitWithError() {
  echo "*ERROR* $1"
  exit 1
}

[[ -z $VIYA_NAMESPACE ]] && exitWithError "Environment variable VIYA_NAMESPACE not defined."

CONSULPATH=$1
[[ "$CONSULPATH" == "" ]] && CONSULPATH='config'
echo "Extracting key-values from path: $CONSULPATH"

kubectl -n $VIYA_NAMESPACE exec -it sas-consul-server-0 -c sas-consul-server -- bash -c "export CONSUL_HTTP_ADDR=https://localhost:8500; /opt/sas/viya/home/bin/sas-bootstrap-config kv read --recurse $1" > CONSUL-KEY-VALUE.txt

echo "Consul Key-Value pairs has been saved to the file: CONSUL-KEY-VALUE.txt"
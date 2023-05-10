#!/bin/bash

exitWithError() {
  echo "*ERROR* $1"
  exit 1
}

[[ -z $VIYA_NAMESPACE ]] && exitWithError "Environment variable VIYA_NAMESPACE not defined."

#export CONSUL_HTTP_TOKEN=`kubectl exec -q -n $VIYA_NAMESPACE sas-consul-server-0 -c sas-consul-server -- cat /opt/sas/viya/config/etc/SASSecurityCertificateFramework/tokens/consul/default/client.token`
export CONSUL_HTTP_TOKEN=`kubectl -n $VIYA_NAMESPACE get secret sas-consul-client -o go-template='{{(index .data "CONSUL_HTTP_TOKEN")}}'| base64 -d`

echo "CONSUL_HTTP_TOKEN env variable is set to: $CONSUL_HTTP_TOKEN"


[[ ! -z "$CONSUL_HTTP_TOKEN" ]] && echo $CONSUL_HTTP_TOKEN > CONSUL.TOKEN; echo "CONSUL_HTTP_TOKEN was also saved in file: CONSUL.TOKEN"


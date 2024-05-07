#!/bin/bash

exitWithError() {
  echo "*ERROR* $1"
  exit 1
}

[[ -z $VIYA_NAMESPACE ]] && exitWithError "Environment variable VIYA_NAMESPACE not defined."

kubectl -n $VIYA_NAMESPACE delete pods -l app.kubernetes.io/managed-by=sas-cas-operator
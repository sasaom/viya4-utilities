#!/bin/bash

if [[ -z $VIYA_NAMESPACE ]]
then
  echo "*ERROR* Env variable VIYA_NAMESPACE not defined"
  exit 1
fi 

podnames=`kubectl get pods --no-headers -o custom-columns=":metadata.name" -n $VIYA_NAMESPACE`
for apod in $podnames
do 
  kubectl get pod $apod -n $VIYA_NAMESPACE -o json |jq -r '.metadata.labels."app.kubernetes.io/name" as $podname | .status.hostIP as $nodeip | .metadata.labels."workload.sas.com/class" as $class | .spec.containers[] | [$podname, .name,$class,$nodeip,.resources.requests.cpu,.resources.requests.memory,.resources.limits.cpu, .resources.limits.memory] | @csv'
done

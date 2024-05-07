#!/bin/bash

if [[ -z $VIYA_NAMESPACE ]]
then
  echo "*ERROR* Env variable VIYA_NAMESPACE not defined"
  exit 1
fi 

echo "--------------------------------------------"
echo "VIYA_NAMESPACE:$VIYA_NAMESPACE"
echo "--------------------------------------------"

podnames=`kubectl get pods --no-headers -o custom-columns=":metadata.name" -n $VIYA_NAMESPACE`
for apod in $podnames
do 
  echo
  echo $apod
  kubectl get pod $apod -n $VIYA_NAMESPACE -o json |jq -r '.spec.containers[].resources'
done
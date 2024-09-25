#!/bin/bash

SITEYAML=/prj/lab401/deploy/site.yaml
if [[ ! -f $SITEYAML ]]
then
  echo "*ERROR* Cannot open $SITEYAML"
  exit 1
fi 

DEPLOYMENTYAML=tmp_deployments.yaml
yq -e 'select(.kind=="Deployment")' $SITEYAML > $DEPLOYMENTYAML
yq -e '.metadata.name as $deploymentname | .metadata.labels."workload.sas.com/class" as $sasworkload | [$deploymentname, $sasworkload] | @csv' $DEPLOYMENTYAML

#rm -f $DEPLOYMENTYAML


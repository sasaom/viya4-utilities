#!/bin/bash

jobname="sas-start-now-`date +%s`"
kubectl create job sas-start-now-`date +%s` --from cronjob/sas-start-all -n $VIYA_NAMESPACE
echo
echo "The job $jobname is now starting all the Viya4 StatefulSet and Deployments."
echo


#!/bin/bash

jobname="sas-stop-now-`date +%s`"
kubectl create job $jobname --from cronjobs/sas-stop-all  -n $VIYA_NAMESPACE
echo
echo "The job $jobname is now setting all the Viya4 StatefulSet and Deployments replicas to 0."
echo
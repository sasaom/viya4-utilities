#!/bin/bash

mydir=$(dirname "$(readlink -f "$0")")
myFileName=$(basename "$0")

archivefolder=$mydir/"archive"
# wget https://github.com/mikefarah/yq/releases/download/v4.42.1/yq_linux_amd64.tar.gz

usage() {
    echo "Input: name of current deploy. If not specified, the datetime is used."
}
echo ""

mydate=`date '+%Y-%m-%d-%H-%M'`

[[ -d $archivefolder ]] && mkdir $archivefolder

# Get the latest 


# STEP 1: As an administrator with cluster permissions
yq e 'select(.metadata.labels."sas.com/admin" == "cluster-api")' site.yaml > ../cluster/viya4prod/server-side/site-api.yaml

# STEP 2: As an administrator with cluster permission
yq e 'select(.metadata.labels."sas.com/admin" == "cluster-wide")' site.yaml > ../cluster/viya4prod/non-server-side/site-wide.yaml

# STEP 3: As an administrator with local cluster permission
yq e 'select(.metadata.labels."sas.com/admin" == "cluster-local")' site.yaml > ../cluster/viya4prod/non-server-side/site-cluster-local.yaml

# STEP 4: As an administrator with namespace permissions
yq e 'select(.metadata.labels."sas.com/admin" == "namespace")' site.yaml > site-ns.yaml

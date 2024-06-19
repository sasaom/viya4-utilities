#!/bin/bash

exitWithError() {
  echo "*ERROR* > $1"
  exit 1
}

archiveDeployedManifest() {
  newManifest=$1
  prevManifestPath=$2

  if [[ -f $prevManifestPath ]]
  then
    newmd5=`md5sum ${newManifest} | awk '{print $1}'`
    oldmd5=`md5sum $prevManifestPath | awk '{print $1}'`
    if [[ "$newmd5" != "$oldmd5" ]]
    then
      echo "[NEW] $newManifest was modified since the last deploy."
      rm -f $prevManifestPath
      cp $newManifest $prevManifestPath
    else
      echo "$newManifest not changed since the last deploy."
    fi
  else
    echo "[NEW] Cannot find $prevManifestPath. Creating it for the first time."
    cp $newManifest $prevManifestPath
  fi
}

##########################################################################################################
#                                             MAIN
##########################################################################################################
INSTALL="N"
SPLIT="Y"
##########################################################################################################

case "$1" in
  "--install") INSTALL="Y";;
esac
echo
echo "=============================================================================="
echo "Is installation (--install): $INSTALL"
echo "Crete separate yaml files  : $SPLIT"
echo "=============================================================================="

# These are the files created during the build process:
SITEYAML="site.yaml"
SITE_CLUSTER_API_YAML="site-cluster-api.yaml"
SITE_CLUSTER_WIDE_YAML="site-cluster-wide.yaml"
SITE_CLUSTER_LOCAL_YAML="site-cluster-local.yaml"
SITE_NAMESPACE_YAML="site-namespace.yaml"

[[ ! -f $SITEYAML ]] && exitWithError "Cannot find $SITEYAML"
[[ -z $VIYA4_ARCHIVE ]] && exitWithError "Env variable VIYA4_ARCHIVE is not set."

# These are the files deployed last time (stored in a separate folder)
DEPLOYED_CLUSTER_DIR="$VIYA4_ARCHIVE/cluster"
DEPLOYED_NAMESAPCE_DIR="$VIYA4_ARCHIVE/namespace"
DEPLOYED_SITEYAML="$DEPLOYED_NAMESAPCE_DIR/site.yaml"
DEPLOYED_SITE_CLUSTER_API_YAML="$DEPLOYED_CLUSTER_DIR/site-cluster-api.yaml"
DEPLOYED_SITE_CLUSTER_WIDE_YAML="$DEPLOYED_CLUSTER_DIR/site-cluster-wide.yaml"
DEPLOYED_SITE_CLUSTER_LOCAL_YAML="$DEPLOYED_CLUSTER_DIR/site-cluster-local.yaml"
DEPLOYED_SITE_NAMESPACE_YAML="$DEPLOYED_NAMESAPCE_DIR/site-namespace.yaml"


echo "DEPLOY $VIYA_NAMESPACE"

echo "------------------------------------------------------------------------------"
echo 'Step 1: --selector="sas.com/admin=cluster-api" --server-side --force-conflicts'
kubectl apply --selector="sas.com/admin=cluster-api" --server-side --force-conflicts -f $SITEYAML
sleep 3
echo 
echo 'Step 2: --selector="sas.com/admin=cluster-wide"'
kubectl apply --selector="sas.com/admin=cluster-wide" -f $SITEYAML
sleep 3
echo 
echo 'Step 3: --selector="sas.com/admin=cluster-local"'
kubectl apply --selector="sas.com/admin=cluster-local" -f $SITEYAML --prune
sleep 3
echo
echo 'Step 4: --selector="sas.com/admin=namespace"'
if [[ "$INSTALL" == "Y" ]]
  then
    kubectl apply --selector="sas.com/admin=namespace" -f $SITEYAML --prune
  else
    kubectl apply --selector="sas.com/admin=namespace" -f $SITEYAML --prune --prune-allowlist=autoscaling/v2/HorizontalPodAutoscaler
fi
echo 
echo "=============================================================================="
echo "COPY YAML FILES ON $VIYA_ARCHIVE (if changed since the last deploy)"

[[ ! -d $DEPLOYED_CLUSTER_DIR ]] && mkdir -p $DEPLOYED_CLUSTER_DIR
[[ ! -d $DEPLOYED_NAMESAPCE_DIR ]] && mkdir -p $DEPLOYED_NAMESAPCE_DIR

splitfiles=(${SITEYAML})
if [[ "$SPLIT"  == "Y" ]]
then
  splitfiles=(${SITE_CLUSTER_API_YAML} ${SITE_CLUSTER_WIDE_YAML} ${SITE_CLUSTER_LOCAL_YAML} ${SITE_NAMESPACE_YAML})

  archiveDeployedManifest ${SITE_CLUSTER_API_YAML} ${DEPLOYED_SITE_CLUSTER_API_YAML}
  archiveDeployedManifest ${SITE_CLUSTER_WIDE_YAML} ${DEPLOYED_SITE_CLUSTER_WIDE_YAML}
  archiveDeployedManifest ${SITE_CLUSTER_LOCAL_YAML} ${DEPLOYED_SITE_CLUSTER_WIDE_YAML}
  archiveDeployedManifest ${SITE_NAMESPACE_YAML} ${DEPLOYED_SITE_CLUSTER_WIDE_YAML}
else
  archiveDeployedManifest ${SITEYAML} ${DEPLOYED_SITEYAML}
fi

echo "=============================================================================="
echo
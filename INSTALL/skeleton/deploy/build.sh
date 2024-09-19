#!/bin/bash

printUsage() {
  echo
  echo  "Usage: $0 <params>"
  echo
  echo  " --install (use only the first time you are deploying Viya4)"
  echo  " --split (split the site.yaml into four files, one for each deployment step and diff with the previous run)"
  echo
}


exitWithError() {
  echo "*ERROR* > $1"
  exit 1
}

buildSiteYaml() {

  echo "=============================================================================="
  echo "BUILD site.yaml WITH KUSTOMIZE"
  echo
  echo "kustomize build -o $SITEYAML"
  kustomize build -o $SITEYAML
  echo
}

splitSiteYaml() {
  # if SPLIT is set, then split site.yaml into for different files
  echo "=============================================================================="
  echo "SPLIT site.yaml in multiple files"
  echo
  if [[ "$SPLIT"  == "Y" ]]
  then
    echo "STEP 1: ${SITE_CLUSTER_API_YAML} (for an administrator with cluster permissions)"
    yq e 'select(.metadata.labels."sas.com/admin" == "cluster-api")' $SITEYAML > ${SITE_CLUSTER_API_YAML}
    echo "STEP 2: ${SITE_CLUSTER_WIDE_YAML} (for an administrator with cluster permission)"
    yq e 'select(.metadata.labels."sas.com/admin" == "cluster-wide")' $SITEYAML > ${SITE_CLUSTER_WIDE_YAML}
    echo "STEP 3: ${SITE_CLUSTER_LOCAL_YAML} (for an administrator with local cluster permission)"
    yq e 'select(.metadata.labels."sas.com/admin" == "cluster-local")' $SITEYAML > ${SITE_CLUSTER_LOCAL_YAML}
    echo "STEP 4: ${SITE_NAMESPACE_YAML} (for an administrator with namespace permissions)"
    yq e 'select(.metadata.labels."sas.com/admin" == "namespace")' $SITEYAML > ${SITE_NAMESPACE_YAML}
  fi
  echo
}

diffFiles() {
  newfile=$1
  oldfile=$2

  newmd5=`md5sum ${newfile} | awk '{print $1}'`
  oldmd5=`md5sum ${oldfile} | awk '{print $1}'`

  if [[ ! -f $oldfile ]]
    then
      echo "Cannot find a previous version of $oldfile."
    else
      if [[ "$newmd5" != "$oldmd5" ]]
      then
        echo "[**Updated**] ${newfile}"
      else
        echo "[No changes]  ${newfile}"
      fi
  fi
}


##########################################################################################################
#                                             MAIN
##########################################################################################################
BUILD="Y"
SPLIT="Y"
##########################################################################################################

SITEYAML="site.yaml"
SITE_CLUSTER_API_YAML="site-cluster-api.yaml"
SITE_CLUSTER_WIDE_YAML="site-cluster-wide.yaml"
SITE_CLUSTER_LOCAL_YAML="site-cluster-local.yaml"
SITE_NAMESPACE_YAML="site-namespace.yaml"

# These are the files deployed last time (stored in a separate folder)
DEPLOYED_CLUSTER_DIR="$VIYA4_ARCHIVE/cluster"
DEPLOYED_NAMESAPCE_DIR="$VIYA4_ARCHIVE/namespace"

[[ ! -d $DEPLOYED_CLUSTER_DIR ]] && mkdir -p $DEPLOYED_CLUSTER_DIR
[[ ! -d $DEPLOYED_NAMESAPCE_DIR ]] && mkdir -p $DEPLOYED_NAMESAPCE_DIR

DEPLOYED_SITEYAML="$DEPLOYED_NAMESAPCE_DIR/site.yaml"
DEPLOYED_SITE_CLUSTER_API_YAML="$DEPLOYED_CLUSTER_DIR/site-cluster-api.yaml"
DEPLOYED_SITE_CLUSTER_WIDE_YAML="$DEPLOYED_CLUSTER_DIR/site-cluster-wide.yaml"
DEPLOYED_SITE_CLUSTER_LOCAL_YAML="$DEPLOYED_CLUSTER_DIR/site-cluster-local.yaml"
DEPLOYED_SITE_NAMESPACE_YAML="$DEPLOYED_NAMESAPCE_DIR/site-namespace.yaml"

case "$1" in
  "--nobuild") BUILD="N";;
esac

echo
echo "=============================================================================="
echo "Build required (--nobuild): $BUILD"
echo "Crete separate yaml files : $SPLIT"


[[ "$BUILD" == "Y" ]] && buildSiteYaml
splitSiteYaml

if [[ "$SPLIT"  == "Y" ]]
then
  diffFiles ${SITE_CLUSTER_API_YAML} ${DEPLOYED_SITE_CLUSTER_API_YAML}
  diffFiles ${SITE_CLUSTER_WIDE_YAML} ${DEPLOYED_SITE_CLUSTER_WIDE_YAML}
  diffFiles ${SITE_CLUSTER_LOCAL_YAML} ${DEPLOYED_SITE_CLUSTER_LOCAL_YAML}
  diffFiles ${SITE_NAMESPACE_YAML} ${DEPLOYED_SITE_NAMESPACE_YAML}
else
  diffFiles ${SITEYAML} ${DEPLOYED_SITEYAML}
fi

echo "=============================================================================="
echo
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
    echo "STEP 1: ${SITE_API_YAML} (for an administrator with cluster permissions)"
    yq e 'select(.metadata.labels."sas.com/admin" == "cluster-api")' $SITEYAML > ${SITE_API_YAML}
    echo "STEP 2: ${SITE_WIDE_YAML} (for an administrator with cluster permission)"
    yq e 'select(.metadata.labels."sas.com/admin" == "cluster-wide")' $SITEYAML > ${SITE_WIDE_YAML}
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

  #[[ ! -d $VIYA4_ARCHIVE/to-deploy ]] && mkdir $VIYA4_ARCHIVE/to-deploy

  newmd5=`md5sum ${newfile} | awk '{print $1}'`
  oldmd5=`md5sum ${oldfile} | awk '{print $1}'`

  if [[ "$newmd5" != "$oldmd5" ]]
  then
    echo "[**Updated**] ${newfile}"
    #cp -f ${newfile} $VIYA4_ARCHIVE/to-deploy/${newfile}
  else
    echo "[No changes]  ${newfile}"
  fi
}


diffSiteYaml() {

  echo "=============================================================================="
  echo "CHECK FILES MODIFIED SINCE THE LAST DEPLOYMENT"
  echo
  [[ -z $VIYA4_ARCHIVE ]] && exitWithError "Env variable VIYA4_ARCHIVE is not set."
  [[ ! -f $SITEYAML ]] && exitWithError "Cannot find $SITEYAML"

  [[ ! -d $VIYA4_ARCHIVE ]] && mkdir -p $VIYA4_ARCHIVE

  # Comparing with the files saved in $VIYA4_ARCHIVE
  if [[ "$SPLIT"  == "N" ]]
  then
    if [[ ! -f $VIYA4_ARCHIVE/$SITEYAML ]]
      then
        echo "Cannot find a previous version of $SITEYAML in $VIYA4_ARCHIVE."
        #cp $SITEYAML $VIYA4_ARCHIVE/$SITEYAML
      else
        # compare previous site.yaml
        diffFiles $SITEYAML $VIYA4_ARCHIVE/$SITEYAML
    fi
  else
    splitfiles=(${SITE_API_YAML} ${SITE_WIDE_YAML} ${SITE_CLUSTER_LOCAL_YAML} ${SITE_NAMESPACE_YAML})

    for splityaml in ${splitfiles[@]} 
    do
      if [[ ! -f $VIYA4_ARCHIVE/$splityaml ]]
      then
        echo "Cannot find a previous version of $splityaml in $VIYA4_ARCHIVE."
        #cp ${splityaml} $VIYA4_ARCHIVE/$splityaml
      else
        diffFiles $splityaml $VIYA4_ARCHIVE/$splityaml
      fi
    done
  fi
  echo
}

##########################################################################################################
#                                             MAIN
##########################################################################################################
BUILD="Y"
SPLIT="Y"
##########################################################################################################

SITEYAML="site.yaml"
SITE_API_YAML="site-api.yaml"
SITE_WIDE_YAML="site-wide.yaml"
SITE_CLUSTER_LOCAL_YAML="site-cluster-local.yaml"
SITE_NAMESPACE_YAML="site-namespace.yaml"

case "$1" in
  "--nobuild") BUILD="N";;
esac

echo
echo "=============================================================================="
echo "Build required (--nobuild): $BUILD"
echo "Crete separate yaml files : $SPLIT"


[[ "$BUILD" == "Y" ]] && buildSiteYaml
splitSiteYaml
diffSiteYaml

echo "=============================================================================="
echo
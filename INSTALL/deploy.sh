#!/bin/bash

exitWithError() {
  echo "*ERROR* > $1"
  exit 1
}

#---------------------------------------------------------------------------------------------------------
# MAIN
#---------------------------------------------------------------------------------------------------------
INSTALL="N"
SPLIT="Y"
#---------------------------------------------------------------------------------------------------------

case "$1" in
  "--install") INSTALL="Y";;
esac
echo
echo "=============================================================================="
echo "Is installation (--install): $INSTALL"
echo "Crete separate yaml files  : $SPLIT"
echo "=============================================================================="

SITEYAML="site.yaml"
SITE_API_YAML="site-api.yaml"
SITE_WIDE_YAML="site-wide.yaml"
SITE_CLUSTER_LOCAL_YAML="site-cluster-local.yaml"
SITE_NAMESPACE_YAML="site-namespace.yaml"

[[ ! -f $SITEYAML ]] && exitWithError "Cannot find $SITEYAML"
[[ -z $VIYA4_ARCHIVE ]] && exitWithError "Env variable $VIYA4_ARCHIVE is not set."

mydate=$(date '+%Y-%m-%d-%H-%M')

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

[[ ! -d $VIYA4_ARCHIVE ]] && mkdir $VIYA4_ARCHIVE

splitfiles=(${SITEYAML})
if [[ "$SPLIT"  == "Y" ]]
then
  splitfiles=(${SITE_API_YAML} ${SITE_WIDE_YAML} ${SITE_CLUSTER_LOCAL_YAML} ${SITE_NAMESPACE_YAML})
fi

for splityaml in ${splitfiles[@]} 
do
  if [[ -L $VIYA4_ARCHIVE/$splityaml ]]
  then
    newmd5=`md5sum ${splityaml} | awk '{print $1}'`
    oldmd5=`md5sum $VIYA4_ARCHIVE/$splityaml | awk '{print $1}'`
    if [[ "$newmd5" != "$oldmd5" ]]
    then
      echo "[NEW] $splityaml was modified since the last deploy."
      cp $splityaml $VIYA4_ARCHIVE/$mydate-$splityaml
      rm -f $VIYA4_ARCHIVE/$splityaml
      ln -s $VIYA4_ARCHIVE/$mydate-$splityaml $VIYA4_ARCHIVE/$splityaml
    else
      echo "$splityaml not changed since the last deploy."
    fi
  else
    echo "[NEW] Cannot find $VIYA4_ARCHIVE/$splityaml. Creating it for the first time."
    cp $splityaml $VIYA4_ARCHIVE/$mydate-$splityaml
    ln -s $VIYA4_ARCHIVE/$mydate-$splityaml $VIYA4_ARCHIVE/$splityaml
  fi
done
echo "=============================================================================="
echo
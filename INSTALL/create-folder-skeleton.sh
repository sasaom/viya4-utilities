#!/bin/bash

source ../.sasaom-common.sh

echo "-----------------------------------------------------------"
echo "Create Viya4 installation folders"
echo
echo "BASEDIR : $BASEDIR"
echo "VIYAENV : $VIYAENV"
echo "INSTDIR : $BASEDIR/$VIYAENV"
echo "-----------------------------------------------------------"

INSTDIR="$BASEDIR/$VIYAENV"

if [[ ! -d $INSTDIR ]] 
then 
    echo "> Creating $INSTDIR"
    mkdir -p $INSTDIR
else
    echo "> $INSTDIR just exists."
fi

VIYA4_DEPLOY=${INSTDIR}/deploy
VIYA4_INFRA=${VIYA4_DEPLOY}/infra
VIYA4_MONITOR=${INSTDIR}/monitoring-logging
VIYA4_TOOLS=${INSTDIR}/bin
PATH=${VIYA4_TOOLS}:$PATH
VIYA_NAMESPACE=$VIYAENV

[[ ! -d "$VIYA4_DEPLOY" ]] && mkdir $VIYA4_DEPLOY
[[ ! -d "$VIYA4_INFRA" ]] && mkdir $VIYA4_INFRA
[[ ! -d "$VIYA4_MONITOR" ]] && mkdir $VIYA4_MONITOR
[[ ! -d "$VIYA4_TOOLS" ]] && mkdir $VIYA4_TOOLS


tee ${INSTDIR}/VIYA4ENV.sh <<EOF
export VIYA4_ROOT=${INSTDIR}
export VIYA4_ARTIFACTS=\${VIYA4_ROOT}/artifacts
export VIYA4_DEPLOY=\${VIYA4_ROOT}/deploy
export VIYA4_ARCHIVE=\${VIYA4_DEPLOY}/00-manifests
export VIYA4_INFRA=\${VIYA4_DEPLOY}/infra
export VIYA4_MONITOR=\${VIYA4_ROOT}/monitor-logging
export VIYA4_RESOURCES=\${VIYA4_ROOT}/resources
export VIYA4_TOOLS=\${VIYA4_ROOT}/bin
export VIYA4_UTILITIES=\${VIYA4_ROOT}/utilities
export VIYA_NAMESPACE=$VIYAENV
export PATH=\${VIYA4_TOOLS}:\$PATH
export USER_DIR=\${VIYA4_ROOT}/monitoring-logging

echo "------------------------------------------------"
echo "Viya4 environment settings"
echo
echo "VIYA4_ROOT            : \$VIYA4_ROOT"
echo "VIYA_NAMESPACE        : \$VIYA_NAMESPACE"
echo "kustomize version     : \$(kustomize version)"
echo "kubectl version       : \$(kubectl version --output=json | jq -r '.clientVersion.gitVersion')"
echo "------------------------------------------------"

echo "cd \${VIYA4_ROOT}"
cd \${VIYA4_ROOT}
EOF

echo "DONE"